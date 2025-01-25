---@class nucleo.layout-ctx
---@field qbuf number
---@field rbuf number
---@field pbuf number

---@class nucleo.layout
---@field new fun(): nucleo.layout
---@field open fun(self, ctx: nucleo.layout-ctx): nucleo.layout-ctx
---@field close fun(self)
---@field qwin number
---@field rwin number
---@field pwin number
---@field is_closed boolean

---@type table<string, nucleo.layout>
local layouts = {
  default = require("layouts.default").new(),
}

return layouts
