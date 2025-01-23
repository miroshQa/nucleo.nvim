---@class Matcher
local Matcher = {}


-- without fuzzy finding yet
function Matcher.new()
  ---@class Matcher
  local self = setmetatable({}, { __index = Matcher })
  self._all_items = {}
  self._matched = {}
  self.pattern = ""
  return self
end

function Matcher:add_items(items)
  for _, val in ipairs(items) do
    table.insert(self._all_items, val)
    if string.find(val, self.pattern) then
      table.insert(self._matched, val)
    end
  end
end

function Matcher:matched_items(left, right)
  local res = {}
  for i = left, right do
    table.insert(res, self._matched[i + 1])
  end
  return res
end

function Matcher:matched_item_count()
  return #self._matched
end

function Matcher:item_count()
  return #self._all_items
end

function Matcher:reparse()
  self._matched = {}
  for _, val in ipairs(self._all_items) do
    if string.find(val, self.pattern) then
      table.insert(self._matched, val)
    end
  end
end

return Matcher
