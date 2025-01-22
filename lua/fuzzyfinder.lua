require("PickerControl")
local Picker = require("Picker")
local PickerView = require("PickerView")
local Matcher = require("Matcher")
local FilesSource = require("FilesSource")
local state = require("NucleoState")

local function fuzzyFinder()
  local source = FilesSource.new()
  local matcher = Matcher.new()
  state.last_picker = Picker.new(source, matcher)
  PickerView.clear()
  PickerView.render(state.last_picker)
end

return fuzzyFinder
