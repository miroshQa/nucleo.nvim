local M = {}

local libpath = debug.getinfo(1).source:match('@?(.*/)') .. "../nucleo_matcher/target/release/lib?.so"
package.cpath = package.cpath .. ";" .. libpath

require("PickerControl")
local Picker = require("Picker")
local PickerView = require("PickerView")
local state = require("NucleoState")

function M.files()
  state.last_picker = Picker.new(nil, nil)
  PickerView.clear()
  PickerView.render(state.last_picker)
end


return M
