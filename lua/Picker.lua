local view = require("PickerView")
local matcher = require("nucleo_matcher")

---@class Picker
local Picker = {}

---comment
---@return Picker
---@param source Source
---@param matcher Matcher
function Picker.new()
  ---@class Picker
  local self = setmetatable({}, { __index = Picker })
  self.selected = 0 -- 0 means selected first item

  local source = require("sources.files")
  source.start(function ()
    print("source exited")
  end)

  self.timer = vim.uv.new_timer()
  self.timer:start(30, 30, function()
    vim.schedule(function ()
      matcher.tick(10)
      view.render(self)
    end)
  end)


  return self
end

return Picker
