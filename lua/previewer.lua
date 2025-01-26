
local M = {}

local previewer = {}

function M.new()
  local self = setmetatable({}, { __index = previewer })
  self.buf = vim.api.nvim_create_buf(false, true)
  return self
end

function previewer:destroy()
  vim.api.nvim_buf_delete(self.buf, {force = true})
end

function previewer:display(file_name)
  local fd, err = vim.uv.fs_open(file_name, "r", 0)
  if not fd then
    return nil, err
  end
  local stats, err = vim.uv.fs_fstat(fd)
  if not stats or stats.size > 1024 * 100 then
    return
  end
end

return M
