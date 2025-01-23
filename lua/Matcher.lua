---@class Matcher
local Matcher = {}

function Matcher.new()
  local self = setmetatable({}, { __index = Matcher })
  self._items = {}
  return self
end

function Matcher:add_items(items)
  for _, val in ipairs(items) do
    table.insert(self._items, {score = 1, data = val})
  end
end

function Matcher:matched_items(left, right)
  return vim.iter(self._items):map(function (x)
    if x.score > 0 and x.data ~= "" then
      return x.data
    end
  end):totable()
end

function Matcher:matched_item_count()
  local total = 0
  for _, val in ipairs(self._items) do
    if val.score > 0 and val.data ~= 0 then
      total = total + 1
    end
  end
  return total
end

function Matcher:item_count()
  return #self._items
end

function Matcher:reparse(pattern)
  for _, val in ipairs(self._items) do
    if string.find(val.data, pattern) then
      val.score = 1
    else
      val.score = 0
    end
  end
end

return Matcher
