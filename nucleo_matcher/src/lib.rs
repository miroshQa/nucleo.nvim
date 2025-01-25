use mlua::prelude::*;
use mlua::{Lua, Table, Value};

use lazy_static::lazy_static;
use nucleo::pattern::{CaseMatching, Normalization};
use nucleo::{Config, Nucleo};
use std::sync::{Arc, Mutex};
use std::cmp::min;

struct MatcherItem {
    matchable: String,
    // Arbitrary data, it can be ripgrep match positions in the file, serialized json (lua table), whatever
    data: String,
}

// Hmmm... Is it possible to define it easier?
lazy_static! {
    static ref MATCHER: Arc<Mutex<Nucleo<MatcherItem>>> = Arc::new(Mutex::new(Nucleo::new(Config::DEFAULT, Arc::new(|| {}), None, 1)));
}

fn add_item(lua: &Lua, tbl: Table) -> mlua::Result<()> {
    let matcher = MATCHER.lock().unwrap();
    // that is pretty damn inefficient I guess
    let injector = matcher.injector();
    let matchable: String = tbl.raw_get("matchable")?;
    let data: String = tbl.raw_get("data")?;
    let item = MatcherItem { matchable, data };
    injector.push(item, |item, row| {
        row[0] = item.matchable.clone().into();
    });
    Ok(())
}

fn add_item_string(lua: &Lua, str: String) -> mlua::Result<()> {
    let matcher = MATCHER.lock().unwrap();
    let injector = matcher.injector();
    let item = MatcherItem { matchable: str, data: String::new() };
    injector.push(item, |item, row| {
        row[0] = item.matchable.clone().into();
    });
    Ok(())
}

fn matched_items(lua: &Lua, (left, right): (u32, u32)) -> mlua::Result<LuaTable> {
    let matcher = MATCHER.lock().unwrap();
    let res_tbl = lua.create_table()?;
    let snapshot = matcher.snapshot();
    let right = min(right, snapshot.matched_item_count());
    for value in snapshot.matched_items(left..right) {
        // Actually probably we can don't use lua tables at all, I heard something about user data, 
        // Need to study that
        // Also I should consider to use array part instead hash table (assume that first item in
        // lua table is matchable and second is data)
        let tbl = lua.create_table()?;
        tbl.raw_set("matchable", value.data.matchable.clone())?;
        tbl.raw_set("data", value.data.data.clone())?;
        res_tbl.raw_push(tbl).unwrap();
    }
    Ok(res_tbl)
}

// return true if matcher didn't complete parse
fn tick(lua: &Lua, timeout: u64) -> mlua::Result<bool> {
    let mut matcher = MATCHER.lock().unwrap();
    Ok(matcher.tick(timeout).running)
}

fn item_count(lua: &Lua, _: ()) -> mlua::Result<u32> {
    let matcher = MATCHER.lock().unwrap();
    let snapshot = matcher.snapshot();
    Ok(snapshot.item_count())
}

fn matched_item_count(lua: &Lua, _: ()) -> mlua::Result<u32> {
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
    matcher.restart(true);
    Ok(())
}

#[mlua::lua_module(skip_memory_check)]
fn nucleo_matcher(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("add_item", lua.create_function(add_item)?)?;
    exports.set("add_item_string", lua.create_function(add_item_string)?)?;
    // Also I probably should add function matched_items_matchable that will return only tbl of
    // strings
    exports.set("item_count", lua.create_function(item_count)?)?;
    exports.set("matched_item_count", lua.create_function(matched_item_count)?)?;
    exports.set("matched_items", lua.create_function(matched_items)?)?;
    exports.set("tick", lua.create_function(tick)?)?;
    exports.set("restart", lua.create_function(restart)?)?;
    exports.set("set_pattern", lua.create_function(set_pattern)?)?;
    Ok(exports)
}
