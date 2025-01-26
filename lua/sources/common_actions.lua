
---@type table<string, nucleo.picker.action>
local actions = {
  up = function(picker)
    vim.api.nvim_buf_call(picker.prompt.buf, function()
      vim.cmd("norm! k")
    end)
  end,
  down = function(picker)
    vim.api.nvim_buf_call(picker.prompt.buf, function()
      vim.cmd("norm! j")
    end)
  end,
  hide = function(picker)
    print("try hide")
    picker.renderer:stop()
    print("picker should be collected after layout:destroy()")
    picker.layout:close()
  end,
}

return actions
