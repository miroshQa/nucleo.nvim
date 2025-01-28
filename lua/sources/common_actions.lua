
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
    picker.matcher.set_status(1)
    picker.renderer:stop()
    picker.layout:close()
  end,
}

return actions
