use mlua::prelude::*;
use mlua::{Lua, Table, Value};

use lazy_static::lazy_static;
use nucleo::pattern::{CaseMatching, Normalization};
use nucleo::{Config, Nucleo};
use std::sync::{Arc, Mutex};
use std::cmp::min;

// OMG, I HATE RUST, I DON'T FUCKING KNOW HOW TO AVOID THIS BULLSHIG, IT SEEMS THE ONLY WAY TO
// DEFINE FUCKING file scope level VARIABLE in this idiotic language OMGMGMGMGMGMGMGMG
lazy_static! {
    static ref MATCHER: Arc<Mutex<Nucleo<String>>> = Arc::new(Mutex::new(Nucleo::new(Config::DEFAULT, Arc::new(|| {}), None, 1)));
}

fn add_items(lua: &Lua, table: Table) -> mlua::Result<()> {
    let matcher = MATCHER.lock().unwrap();
    // that is pretty damn inefficient I guess
    let injector = matcher.injector();
    for value in table.sequence_values::<String>() {
        let value = value.unwrap();
        injector.push(value, |str, row| {
            row[0] = str.clone().into();
        });
    }
    Ok(())
}

fn matched_items(lua: &Lua, (left, right): (u32, u32)) -> mlua::Result<LuaTable> {
    let matcher = MATCHER.lock().unwrap();
    let tbl = lua.create_table()?;
    let snapshot = matcher.snapshot();
    let right = min(right, snapshot.matched_item_count());
    for value in snapshot.matched_items(left..right) {
        let value = value.data.clone();
        tbl.raw_push(value).unwrap();
    }
    Ok(tbl)
}

fn reparse(lua: &Lua, _: ()) -> mlua::Result<()> {
    let mut matcher = MATCHER.lock().unwrap();
    matcher.tick(20);
    Ok(())
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

#[mlua::lua_module(skip_memory_check)]
fn nucleo_matcher(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set("add_items", lua.create_function(add_items)?)?;
    exports.set("matched_items", lua.create_function(matched_items)?)?;
    exports.set("matched_item_count", lua.create_function(matched_item_count)?)?;
    exports.set("item_count", lua.create_function(item_count)?)?;
    exports.set("reparse", lua.create_function(reparse)?)?;
    exports.set("set_pattern", lua.create_function(set_pattern)?)?;
    Ok(exports)
}
