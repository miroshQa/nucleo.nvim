local M = {}


---@class nucleo.Picker.Prompt
local prompt = {}

---@param picker nucleo.Picker
function M.new(picker)
---@class nucleo.Picker.Prompt
  local self = setmetatable({}, { __index = prompt })
  self.buf = vim.api.nvim_create_buf(false, true)
  self.selected = 0
  self.matches_hl_ns = vim.api.nvim_create_namespace("m_hl_ns")
  self.picker = picker
  return self
end

function prompt:move_down()
  local matched = self.picker.matcher:matched_item_count()
  self.selected = (self.selected + 1) % matched
  vim.api.nvim_buf_call(self.buf, function()
    vim.cmd("norm! j")
  end)
  self.picker.previewer:update()
end

function prompt:move_up()
  local matched = self.picker.matcher:matched_item_count()
  self.selected = (self.selected - 1) % matched
  vim.api.nvim_buf_call(self.buf, function()
    vim.cmd("norm! k")
  end)
  self.picker.previewer:update()
end

function prompt:update()
  vim.api.nvim_buf_clear_namespace(self.buf, self.matches_hl_ns, 0, -1)
  local win_height = vim.api.nvim_win_get_height(self.picker.layout.prompt_win)
  -- win cursor shouldn't be ever greater than win_height
  -- (unless we start to load in buffer more items than win_height to request matched items less often and 
  -- gain performance benefits (in theory, I still not sure if it is really necessary?)
  local win_cursor = vim.api.nvim_win_get_cursor(self.picker.layout.prompt_win)[1] - 1 or 0
  local left = self.selected - win_cursor
  local right = self.selected + (win_height - win_cursor)
  -- print(win_cursor, self.selected, "(", left, right, ")")

  local items = self.picker.matcher:matched_items(left, right)
  local matchables = vim.iter(items):map(function(v) return v[1] end):totable()
  vim.api.nvim_buf_set_lines(self.picker.prompt.buf, 0, -1, false, matchables)

  for i, item in ipairs(items) do
    for _, col in ipairs(item[3]) do
      vim.api.nvim_buf_add_highlight(self.buf, self.matches_hl_ns, "Statement", i - 1, col, col + 1)
    end
  end
end


function prompt:destroy()
  vim.api.nvim_buf_delete(self.buf, {force = true})
end

return M
