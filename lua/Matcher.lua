---@class Matcher
local self = {}


self._all_items = {}
self._matched = {}
self._pattern = ""

function self.add_items(items)
  for _, val in ipairs(items) do
    table.insert(self._all_items, val)
    if string.find(val, self._pattern) then
      table.insert(self._matched, val)
    end
  end
end

function self.matched_items(left, right)
  local res = {}
  for i = left, right do
    table.insert(res, self._matched[i + 1])
  end
  return res
end

function self.matched_item_count()
  return #self._matched
end

function self.set_pattern(pattern)
  self._pattern = pattern
end

function self.item_count()
  return #self._all_items
end

function self.reparse()
  self._matched = {}
  for _, val in ipairs(self._all_items) do
    if string.find(val, self._pattern) then
      table.insert(self._matched, val)
    end
  end
end

return self
