
---@type table<string, nucleo.picker.action>
local actions = {
  up = function(picker)
    picker.prompt:move_up()
  end,
  down = function(picker)
    picker.prompt:move_down()
  end,
  hide = function(picker)
    picker.matcher:set_status(1)
    picker.renderer:stop()
    picker.layout:close()
  end,
  open = function(picker)
    local selected = picker.prompt.selected
    local item = picker.matcher:get_matched_item(selected)
    local file_name = item[1]
    picker.renderer:stop()
    picker.layout:close()
    vim.cmd("e " .. file_name)
  end
}

return actions
