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
  local start = vim.uv.now()
  local last_render = vim.uv.now()
  local pending = false

  self.source:start(self.matcher,
    function(a, b)
      local now = vim.uv.now()
      if not pending and now - last_render > 30 then
        pending = true

        vim.schedule(function()
          local running, changed = self.matcher:tick(10)
          if changed then
            self.query:update()
            self.prompt:update()
            self.previewer:update()
            print("rendered")
          end
          last_render = vim.uv.now()
          pending = false
        end)

      end
      self.matcher:add_item(a, b)
    end,

    function()
      print("source took ms: " .. (vim.uv.now() - start))
    end)
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
