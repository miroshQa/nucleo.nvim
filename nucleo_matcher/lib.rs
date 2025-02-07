use mlua::prelude::*;
use mlua::Lua;

use lazy_static::lazy_static;
use nucleo::pattern::{CaseMatching, Normalization};
use nucleo::{Config, Nucleo, Matcher};
use std::sync::{Arc, Mutex};
use std::cmp::min;

struct MatcherItem {
    matchable: String,
    // Arbitrary data, it can be ripgrep match positions in the file, serialized json (lua table), whatever
    data: String,
}

// Hmmm... Is it possible to define it easier?
lazy_static! {
    static ref MATCHER: Mutex<Nucleo<MatcherItem>> = Mutex::new(Nucleo::new(Config::DEFAULT, Arc::new(|| {}), None, 1));
    static ref LOWLEVEL_MATCHER: Mutex<Matcher> = Mutex::new(Matcher::new(Config::DEFAULT));
    static ref STATUS: Mutex<i32> = Mutex::new(0);
}

fn set_status(_: &Lua, new_status: i32) -> mlua::Result<()> {
    let mut status = STATUS.lock().unwrap();
    *status = new_status;
    Ok(())
}

fn add_item(_: &Lua, (matchable, data): (String, String)) -> mlua::Result<i32> {
    let matcher = MATCHER.lock().unwrap();
    // Hm, will it be faster if i start to reuse some static injector
    let injector = matcher.injector();
    let item = MatcherItem { matchable, data };
    injector.push(item, |item, row| {
        row[0] = item.matchable.clone().into();
    });
    let status = STATUS.lock().unwrap().clone();
    Ok(status)
}

fn matched_items(lua: &Lua, (left, right): (u32, u32)) -> mlua::Result<LuaTable> {
    let matcher = MATCHER.lock().unwrap();
    let mut lowlevel_matcher = LOWLEVEL_MATCHER.lock().unwrap();
    let mut indices: Vec<u32> = Vec::new();
    let pattern = matcher.pattern.column_pattern(0);
    let res_tbl = lua.create_table()?;
    let snapshot = matcher.snapshot();
    let right = min(right, snapshot.matched_item_count());
    for item in snapshot.matched_items(left..right) {
        let tbl = lua.create_table_with_capacity(3, 0)?;
        // NOTE: Can we gain benefits in performance and convenience by using user data here?
        // Can easily measure using libuv btw
        pattern.indices(item.matcher_columns[0].slice(..), &mut lowlevel_matcher, &mut indices);
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
}

fn get_matched_item(lua: &Lua, index: u32) -> mlua::Result<LuaTable> {
    let matcher = MATCHER.lock().unwrap();
    let tbl = lua.create_table()?;
    let snapshot = matcher.snapshot();
    let item = snapshot.get_matched_item(index).unwrap();
    tbl.raw_push(item.data.matchable.clone())?;
    tbl.raw_push(item.data.data.clone())?;
    Ok(tbl)
}

// return true if matcher didn't complete parse
fn tick(_: &Lua, timeout: u64) -> mlua::Result<bool> {
    let mut matcher = MATCHER.lock().unwrap();
    Ok(matcher.tick(timeout).running)
}

fn item_count(_: &Lua, _: ()) -> mlua::Result<u32> {
    let matcher = MATCHER.lock().unwrap();
    let snapshot = matcher.snapshot();
    Ok(snapshot.item_count())
}

fn matched_item_count(_: &Lua, _: ()) -> mlua::Result<u32> {
    let matcher = MATCHER.lock().unwrap();
    let snapshot = matcher.snapshot();
    Ok(snapshot.matched_item_count())
}

fn set_pattern(_: &Lua, pattern: String) -> LuaResult<()> {
    let mut matcher = MATCHER.lock().unwrap();
    matcher.pattern.reparse(
        0,
        &pattern,
        CaseMatching::Ignore,
        Normalization::Smart,
        false,
    );
    Ok(())
}

fn restart(_: &Lua, _: ()) -> LuaResult<()> {
    let mut matcher = MATCHER.lock().unwrap();
    matcher.restart(false);
    let mut status = STATUS.lock().unwrap();
    *status = 0;
    Ok(())
}

#[mlua::lua_module(skip_memory_check)]
fn nucleo_matcher(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("add_item", lua.create_function(add_item)?)?;
    exports.set("set_status", lua.create_function(set_status)?)?;
    exports.set("item_count", lua.create_function(item_count)?)?;
    exports.set("matched_item_count", lua.create_function(matched_item_count)?)?;
    exports.set("matched_items", lua.create_function(matched_items)?)?;
    exports.set("get_matched_item", lua.create_function(get_matched_item)?)?;
    exports.set("tick", lua.create_function(tick)?)?;
    exports.set("restart", lua.create_function(restart)?)?;
    exports.set("set_pattern", lua.create_function(set_pattern)?)?;
    Ok(exports)
}
