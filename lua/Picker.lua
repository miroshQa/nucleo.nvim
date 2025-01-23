---@class Picker
local Picker = {}

---comment
---@return Picker
---@param source Source
---@param matcher Matcher
function Picker.new(source, matcher)
  ---@class Picker
  local self = setmetatable({}, { __index = Picker })
  self.matcher = matcher
  self.source = source
  self.selected = 0 -- 0 means selected first item

  self.source:get(function(items)
    if not items then
      return
    end
    self.matcher:add_items(items)
  end)

  return self
end

function Picker:move_selected(direction)
  if direction == "down" then
  else

  end
end

return Picker
