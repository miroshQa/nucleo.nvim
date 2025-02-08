print(debug.getinfo(1).source)
print(debug.getinfo(1).source:match('@?(.*/nucleo.nvim)'))
local libpath = debug.getinfo(1).source:match('@?(.*/nucleo.nvim)') .. "/target/release/lib?.so"
package.cpath = package.cpath .. ";" .. libpath

--- Matcher Interface
--- Currently (and probably always), we only have the Helix Nucleo matcher written in Rust;
--- there is no matcher written in Lua (like the native matcher without dependency, but slow).
---@class nucleo.Matcher
---@field add_item fun(self, matchable: string, data: string): number data - (some serialized lua table as string). Return current status
---@field matched_items fun(self, left: number, right: number): table Return lua tables. First value is matchable second is data. Third is indices to higlight matchable
---@field get_matched_item fun(self, index: number): table Get item by index (0 based indexation) Return lua table. First value is matchable second is data.
---@field tick fun(self, timeout: number): boolean, boolean Return true if matcher still running as first parameter. Return if matched items changed and you should update prompt buffer as second parameter
---@field item_count fun(self): number Returns the amount of items added to memory.
---@field matched_item_count fun(self): number Returns the amount of items matching the pattern.
---@field set_pattern fun(self, pattern: string): nil Sets the pattern
---@field restart fun(self): nil Removes all items added to memory.
---@field set_status fun(self, status: number) You can set arbitrary number to indicate some status for streamer,
---@field get_id fun(self): number You can set arbitrary number to indicate some status for streamer,
--- so after each add_item source should check status and react on it somehow, for example stop streaming if status is 1

---@class nucleo.Registry
---@field new_nucleo_matcher fun(): nucleo.Matcher
---@field get_matcher_by_id fun(id: number): nucleo.Matcher

---@type nucleo.Registry
local Registry = require("matchers_registry")

return Registry
