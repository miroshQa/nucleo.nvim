local Renderer = require("Renderer")
local query = require("query")
local prompt = require("prompt")
local previewer = require("previewer")

local M = {}

---@class nucleo.Picker
local Picker = {}

---Create new picker
---@param spec nucleo.picker.spec
function M.new(spec)
  ---@class nucleo.Picker
  local self = setmetatable({}, { __index = Picker })
  self.source = spec.source
  self.matcher = spec.matcher
  self.layout = spec.layout
  self.renderer = Renderer.new(self)
  self.query = query.new(self)
  self.prompt = prompt.new(self)
  self.previewer = previewer.new(self)
  -- self.formatter = formatter

  for mode, mappings_tbl in pairs(spec.mappings) do
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
  self.source:start(self.matcher)
  self.renderer:start()
end

--- Release memory. It is aboslutely necessary to call this method 
--- If you don't want to leak your memory. Because all other data
--- Can be garbage collected only after we delete buffers
function Picker:destroy()
  self.source:stop()
  self.query:destroy()
  self.prompt:destroy()
  self.previewer:destroy()
end

return M
