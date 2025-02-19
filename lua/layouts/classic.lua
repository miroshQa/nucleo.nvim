local M = {}

---@class nucleo.Layout
local layout = {}

--- Some layout options here (width, height)
function M.new()
---@class nucleo.Layout
  local self = setmetatable({}, { __index = layout })
  self.is_open = false
  return self
end

function layout:clone()
  return M.new()
end

function layout:close()
  for _, win in pairs({ self.prompt_win, self.previewer_win, self.query_win }) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.cmd.stopinsert()
  self.is_open = false
end

---@param picker nucleo.Picker
function layout:open(picker)
  local width = vim.o.columns
  local height = vim.o.lines

  local total_width = 0.8
  local gap_size = 2
  local column_shift_to_center = math.floor((width - (width * total_width)) / 2)

  -- Calculate result window and query window size with column position (y)
  local results_and_query_win_width = math.floor(width * 0.4)

  local query_win_height = math.floor(height * 0.05)
  local results_win_height = math.floor(height * 0.6)
  local query_row_start = math.floor(height * 0.1)
  local results_row_start = query_row_start + query_win_height + gap_size

  local preview_column_shift = column_shift_to_center + results_and_query_win_width + gap_size
  local preview_win_width = math.floor(width * 0.4)
  local preview_win_height = results_win_height + query_win_height + gap_size
  self.query_win = vim.api.nvim_open_win(picker.query.buf, true, {
    relative = 'editor',
    row = query_row_start,
    col = column_shift_to_center,
    width = results_and_query_win_width,
    height = query_win_height,
    border = "rounded",
  })

  self.prompt_win = vim.api.nvim_open_win(picker.prompt.buf, false, {
    relative = 'editor',
    row = results_row_start,
    col = column_shift_to_center,
    width = results_and_query_win_width,
    height = results_win_height,
    border = "rounded",
  })

  self.previewer_win = vim.api.nvim_open_win(picker.previewer.buf, false, {
    relative = 'editor',
    row = query_row_start,
    col = preview_column_shift,
    width = preview_win_width,
    height = preview_win_height,
    border = "rounded",
  })

  vim.wo[self.prompt_win].cursorline = true
  vim.wo[self.prompt_win].wrap = false
  self.is_open = true
  vim.cmd.startinsert()
end

return M
