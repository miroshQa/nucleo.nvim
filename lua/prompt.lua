local M = {}

local prompt = {}

function M.new(picker)
  local self = setmetatable({}, { __index = prompt })
  self.buf = vim.api.nvim_create_buf(false, true)
  self.selected = 0
  self.picker = picker
  return self
end

function prompt:move_down()
end


function prompt:destroy()
  vim.api.nvim_buf_delete(self.buf, {force = true})
end

return M
