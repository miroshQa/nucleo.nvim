local libpath = debug.getinfo(1).source:match('@?(.*/)') .. "./../target/release/lib?.so"
package.cpath = package.cpath .. ";" .. libpath

local M = {}


return M
