--- thanks to blink-cmp for this lifehack
local libpath = debug.getinfo(1).source:match('@?(.*/)') .. "../nucleo_matcher/target/release/lib?.so"
package.cpath = package.cpath .. ";" .. libpath

require("PickerControl")
local Picker = require("Picker")
local PickerView = require("PickerView")
local Matcher = require("Matcher")
Matcher = require("nucleo_matcher")
local FilesSource = require("FilesSource")
local state = require("NucleoState")

local function fuzzyFinder()
  local source = FilesSource.new()
  state.last_picker = Picker.new(source, Matcher)
  PickerView.clear()
  PickerView.render(state.last_picker)
end

return fuzzyFinder
