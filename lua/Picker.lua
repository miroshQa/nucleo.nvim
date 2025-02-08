local Query = require("Query")
local Prompt = require("Prompt")
local Previewer = require("Previewer")
local Renderer = require("Renderer")

local M = {}

---@class nucleo.Picker
local Picker = {}

---@class nucleo.Picker.Components
---@field source nucleo.Source
---@field matcher nucleo.Matcher
---@field layout nucleo.Layout
---@field mappings nucleo.picker.mapings

---Create new picker
---@param components nucleo.Picker.Components
function M.new(components)
  ---@class nucleo.Picker: nucleo.Picker.Components
  local self = setmetatable(components, { __index = Picker })
  self.query = Query.new(self)
  self.prompt = Prompt.new(self)
  self.previewer = Previewer.new(self)
  self.renderer = Renderer.new(self)

  for mode, mappings_tbl in pairs(self.mappings) do
    for key, action in pairs(mappings_tbl) do
      vim.keymap.set(mode, key, function()
        action(self)
      end, {buffer = self.query.buf})
    end
  end

  return self
end

function Picker:run()
  self.layout:open(self)
  local start = vim.uv.now()
  self.source:start(self.matcher, function()
    print("source took ms: " ..  (vim.uv.now() - start))
  end)
  self.renderer:start()
end

--- Release memory. It is aboslutely necessary to call this method 
--- If you don't want to leak your memory. Because all other data
--- Can be garbage collected only after we delete buffers
function Picker:destroy()
  self.query:destroy()
  self.prompt:destroy()
  self.previewer:destroy()
end

return M
