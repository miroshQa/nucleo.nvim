local Registry = require("Registry")
---@alias nucleo.picker.action fun(picker: nucleo.Picker)

---@type table<string, nucleo.picker.action>
local actions = {
  up = function(picker)
    picker.prompt:move_up()
  end,
  down = function(picker)
    picker.prompt:move_down()
  end,
  hide = function(picker)
    picker.layout:close()
    picker:destroy()
  end,
  open = function(picker)
    local selected = picker.prompt.selected
    local item = picker.matcher:get_matched_item(selected)
    local file_name = item[1]
    picker.layout:close()
    vim.cmd("e " .. file_name)
    picker:destroy()
  end
}

return actions
