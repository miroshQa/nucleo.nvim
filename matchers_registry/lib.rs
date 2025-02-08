use mlua::prelude::*;
use mlua::{Function, Lua, UserData, UserDataMethods};

use lazy_static::lazy_static;
use nucleo::pattern::{CaseMatching, Normalization};
use nucleo::{Config, Injector, Matcher, Nucleo};
use std::cmp::min;
use std::collections::HashMap;
use std::fs::OpenOptions;
use std::io::Write;
use std::sync::{Arc, Mutex};

struct MatcherItem {
    matchable: String,
    // Arbitrary data, it can be ripgrep match positions in the file, serialized json (lua table), whatever
    data: String,
}

#[derive(Clone)]
struct NucleoMatcher {
    matcher: Arc<Mutex<Nucleo<MatcherItem>>>,
    status: Arc<Mutex<u32>>,
    injector: Arc<Mutex<Injector<MatcherItem>>>,
    id: u32,
}

lazy_static! {
    static ref REGISTRY: Mutex<HashMap<u32, NucleoMatcher>> = Mutex::new(HashMap::new());
    static ref LOWLEVEL_MATCHER: Mutex<Matcher> = Mutex::new(Matcher::new(Config::DEFAULT));
}

impl UserData for NucleoMatcher {
    fn add_methods<M: UserDataMethods<Self>>(methods: &mut M) {
        methods.add_method_mut(
            "add_item",
            |_, matcher, (matchable, data): (String, String)| {
                let status = matcher.status.lock().unwrap().clone();
                let injector = matcher.injector.lock().unwrap();
                let item = MatcherItem { matchable, data };
                injector.push(item, |item, row| {
                    row[0] = item.matchable.clone().into();
                });
                Ok(status)
            },
        );

        methods.add_method_mut("set_status", |_, matcher, new_status: u32| {
            let mut status = matcher.status.lock().unwrap();
            *status = new_status;
            Ok(())
        });

        methods.add_method_mut(
            "matched_items",
            |lua: &Lua, matcher, (left, right): (u32, u32)| {
                let matcher = matcher.matcher.lock().unwrap();
                let mut lowlevel_matcher = LOWLEVEL_MATCHER.lock().unwrap();
                let mut indices: Vec<u32> = Vec::new();
                let pattern = matcher.pattern.column_pattern(0);
                let res_tbl = lua.create_table()?;
                let snapshot = matcher.snapshot();
                let right = min(right, snapshot.matched_item_count());
                for item in snapshot.matched_items(left..right) {
                    let tbl = lua.create_table_with_capacity(3, 0)?;
                    indices.clear();
                    pattern.indices(
                        item.matcher_columns[0].slice(..),
                        &mut lowlevel_matcher,
                        &mut indices,
                    );
                    indices.sort_unstable();
                    indices.dedup();
                    let tbl_indices = lua.create_table_with_capacity(indices.len(), 0)?;
                    for ind in indices.clone() {
                        tbl_indices.raw_push(ind);
                    }
                    tbl.raw_push(item.data.matchable.clone())?;
                    tbl.raw_push(item.data.data.clone())?;
                    tbl.raw_push(tbl_indices)?;
                    res_tbl.raw_push(tbl).unwrap();
                }
                Ok(res_tbl)
            },
        );

        methods.add_method_mut("set_pattern", |_, matcher, pattern: String| {
            let mut matcher = matcher.matcher.lock().unwrap();
            matcher.pattern.reparse(
                0,
                &pattern,
                CaseMatching::Ignore,
                Normalization::Smart,
                false,
            );
            Ok(())
        });

        methods.add_method_mut("tick", |_, matcher, timeout: u64| {
            let mut matcher = matcher.matcher.lock().unwrap();
            let status = matcher.tick(timeout);
            Ok((status.running, status.changed))
        });

        methods.add_method_mut("item_count", |_, matcher, ()| {
            let matcher = matcher.matcher.lock().unwrap();
            let snapshot = matcher.snapshot();
            Ok(snapshot.item_count())
        });

        methods.add_method_mut("matched_item_count", |_, matcher, ()| {
            let matcher = matcher.matcher.lock().unwrap();
            let snapshot = matcher.snapshot();
            Ok(snapshot.matched_item_count())
        });

        methods.add_method_mut("restart", |_, matcher, ()| {
            let mut status = matcher.status.lock().unwrap();
            let mut matcher = matcher.matcher.lock().unwrap();
            matcher.restart(false);
            *status = 0;
            Ok(())
        });

        methods.add_method_mut("get_matched_item", |lua: &Lua, matcher, index| {
            let matcher = matcher.matcher.lock().unwrap();
            let tbl = lua.create_table()?;
            let snapshot = matcher.snapshot();
            let item = snapshot.get_matched_item(index).unwrap();
            tbl.raw_push(item.data.matchable.clone())?;
            tbl.raw_push(item.data.data.clone())?;
            Ok(tbl)
        });

        methods.add_method_mut("get_id", |_: &Lua, matcher, _: ()| Ok(matcher.id));
    }
}

#[cfg(feature = "debug")]
impl Drop for NucleoMatcher {
    fn drop(&mut self) {
        let mut file = OpenOptions::new()
            .append(true)
            .create(true)
            .open("matchers_registry_log.txt")
            .unwrap();
        let count = Arc::strong_count(&self.matcher);
        let msg = format!(
                "Wrapper for matcher with id {} dropped. Real matcher amount of references: {}",
                self.id,
                count,
            );
        writeln!(file, "{}", msg);
    }
}

#[mlua::lua_module(skip_memory_check)]
fn matchers_registry(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;

    exports.set(
        "new_nucleo_matcher",
        lua.create_function(|_: &Lua, _: ()| {
            let matcher = Arc::new(Mutex::new(Nucleo::new(
                Config::DEFAULT,
                Arc::new(|| {}),
                None,
                1,
            )));
            let injector = Arc::new(Mutex::new(matcher.lock().unwrap().injector()));
            // hmm, that probably may cause issues on 32bit architectures
            let id = Arc::as_ptr(&matcher) as u32;
            let nucleo = NucleoMatcher {
                matcher,
                status: Arc::new(Mutex::new(0)),
                injector,
                id,
            };
            let ret = nucleo.clone();
            let mut registry = REGISTRY.lock().unwrap();
            registry.insert(id, nucleo);
            Ok(ret)
        })?,
    )?;

    exports.set(
        "get_matcher_by_id",
        lua.create_function(|_: &Lua, id: u32| {
            let registry = REGISTRY.lock().unwrap();
            let matcher = registry.get(&id).unwrap();
            Ok(matcher.clone())
        })?,
    )?;

    exports.set(
        "remove_matcher_by_id",
        lua.create_function(|lua: &Lua, id: u32| {
            let mut registry = REGISTRY.lock().unwrap();
            let matcher = registry.remove(&id).unwrap();
            Ok(())
        })?,
    )?;

    // this function useful mostly for debug
    exports.set(
        "get_matcher_references_count",
        lua.create_function(|_: &Lua, id: u32| {
            let registry = REGISTRY.lock().unwrap();
            let matcher = registry.get(&id).unwrap();
            let count = Arc::strong_count(&matcher.matcher);
            Ok(count)
        })?,
    )?;

    Ok(exports)
}
