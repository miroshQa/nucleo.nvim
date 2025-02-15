local Query = require("Query")
local Prompt = require("Prompt")
local Previewer = require("Previewer")

local M = {}

---@class nucleo.Picker
---@field matcher nucleo.Matcher
local Picker = {}

---@alias nucleo.picker.mappings table<string, table<string, nucleo.picker.action>>

---@class nucleo.Picker.Components
---@field source nucleo.Source
---@field matcher nucleo.Matcher
---@field layout nucleo.Layout
---@field mappings nucleo.picker.mappings

---Create new picker
---@param components nucleo.Picker.Components
function M.new(components)
  ---@class nucleo.Picker: nucleo.Picker.Components
  local self = setmetatable(components, { __index = Picker })
  self.query = Query.new(self)
  self.prompt = Prompt.new(self)
  self.previewer = Previewer.new(self)

  for mode, mappings_tbl in pairs(self.mappings) do
    for key, action in pairs(mappings_tbl) do
      vim.keymap.set(mode, key, function()
        action(self)
      end, { buffer = self.query.buf })
    end
  end

  return self
end

function Picker:run()
  self.layout:open(self)
  local thread = self.source:start(self.matcher)
  local timer = vim.uv.new_timer()
  local start = vim.uv.now()

  render = vim.schedule_wrap(function()
    local alive = coroutine.resume(thread)
    if not alive then
      print("took time: " .. vim.uv.now() - start .. "ms")
      return
    end
    local running, changed = self.matcher:tick(10)
    if changed then
      self.query:update()
      self.prompt:update()
      self.previewer:update()
      print("rendered", self.matcher:item_count(), self.matcher:matched_item_count())
    end
    timer:start(10, 0, render)
  end)

  render()
end

--- Release memory. It is aboslutely necessary to call this method
--- If you don't want to leak your memory. Because all other data
--- Can be garbage collected only after we delete buffers
function Picker:destroy()
  self.query:destroy()
  self.prompt:destroy()
  self.previewer:destroy()
  self.matcher = nil
end

return M
