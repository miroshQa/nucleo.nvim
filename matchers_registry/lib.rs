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

// with mutexes we have 2600 on the main thread, without 4600, how to fuck does it work??
#[derive(Clone)]
struct NucleoMatcher {
    matcher: *mut Nucleo<MatcherItem>,
    injector: *mut Injector<MatcherItem>,
}

lazy_static! {
    static ref LOWLEVEL_MATCHER: Mutex<Matcher> = Mutex::new(Matcher::new(Config::DEFAULT));
}

impl UserData for NucleoMatcher {
    fn add_methods<M: UserDataMethods<Self>>(methods: &mut M) {
        methods.add_method_mut(
            "add_item",
            |_, matcher, (matchable, data): (String, String)| {
                let item = MatcherItem { matchable, data };
                let injector = unsafe { matcher.injector.as_ref().unwrap() };
                injector.push(item, |item, row| {
                    row[0] = item.matchable.clone().into();
                });
                Ok(())
            },
        );

        methods.add_method_mut(
            "matched_items",
            |lua: &Lua, matcher, (left, right): (u32, u32)| {
                let matcher = unsafe { matcher.matcher.as_ref().unwrap() };
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
            let matcher = unsafe { matcher.matcher.as_mut().unwrap() };
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
            let matcher = unsafe { matcher.matcher.as_mut().unwrap() };
            let status = matcher.tick(timeout);
            Ok((status.running, status.changed))
        });


        methods.add_method_mut("item_count", |_, matcher, ()| {
            let matcher = unsafe { matcher.matcher.as_ref().unwrap() };
            let snapshot = matcher.snapshot();
            Ok(snapshot.item_count())
        });

        methods.add_method_mut("matched_item_count", |_, matcher, ()| {
            let matcher = unsafe { matcher.matcher.as_ref().unwrap() };
            let snapshot = matcher.snapshot();
            Ok(snapshot.matched_item_count())
        });

        methods.add_method_mut("get_matched_item", |lua: &Lua, matcher, index| {
            let matcher = unsafe { matcher.matcher.as_ref().unwrap() };
            let tbl = lua.create_table()?;
            let snapshot = matcher.snapshot();
            let item = snapshot.get_matched_item(index).unwrap();
            tbl.raw_push(item.data.matchable.clone())?;
            tbl.raw_push(item.data.data.clone())?;
            Ok(tbl)
        });

    }
}

impl Drop for NucleoMatcher {
    fn drop(&mut self) {

        unsafe {
            drop(Box::from_raw(self.matcher));
            drop(Box::from_raw(self.injector));
        };

        #[cfg(feature = "debug")]
        {
            let mut file = OpenOptions::new()
                .append(true)
                .create(true)
                .open("matchers_registry_log.txt")
                .unwrap();
            let msg = format!( "Wrapper for matcher dropped");
            writeln!(file, "{}", msg);
        }
    }
}

#[mlua::lua_module(skip_memory_check)]
fn matchers_registry(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;

    exports.set(
        "new_nucleo_matcher",
        lua.create_function(|_: &Lua, _: ()| {
            let matcher = Box::new(Nucleo::new(Config::DEFAULT, Arc::new(|| {}), None, 1));
            let injector = Box::new(matcher.injector());
            let nucleo = NucleoMatcher {
                matcher: Box::into_raw(matcher),
                injector: Box::into_raw(injector),
            };
            Ok(nucleo)
        })?,
    )?;

    Ok(exports)
}
