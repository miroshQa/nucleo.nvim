local M = {}


---@class nucleo.Prompt
local prompt = {}

---@param picker nucleo.Picker
function M.new(picker)
---@class nucleo.Prompt
  local self = setmetatable({}, { __index = prompt })
  self.buf = vim.api.nvim_create_buf(false, true)
  self.selected = 0
  self.picker = picker
  return self
end

function prompt:move_down()
  --definitely should do some magick with some of the scroll options
end


function prompt:destroy()
  vim.api.nvim_buf_delete(self.buf, {force = true})
end

return M
