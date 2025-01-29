local M = {}


---@class nucleo.Picker.Prompt
local prompt = {}

---@param picker nucleo.Picker
function M.new(picker)
---@class nucleo.Picker.Prompt
  local self = setmetatable({}, { __index = prompt })
  self.buf = vim.api.nvim_create_buf(false, true)
  self.selected = 0
  self.picker = picker
  return self
end

function prompt:move_down()
  --definitely should do some magick with some of the scroll options
end

function prompt:update()
  local cursor = vim.api.nvim_win_get_cursor(self.picker.layout.prompt_win)[0] or 0
  local prompt_win_size = vim.api.nvim_win_get_height(self.picker.layout.prompt_win)
  local items = self.picker.matcher.matched_items(0, cursor + prompt_win_size)
  local matchables = vim.iter(items):map(function(v) return v[1] end):totable()
  vim.api.nvim_buf_set_lines(self.picker.prompt.buf, 0, -1, false, matchables)
end


function prompt:destroy()
  vim.api.nvim_buf_delete(self.buf, {force = true})
end

return M
