---@class Layout
local Layout = {}

---Create new layout. Kind of static method
---@return Layout
---@param picker Picker
---@param width any
---@param height any
function Layout.new_helix_like(picker, width, height)
  ---@class Layout
  local self = setmetatable({}, { __index = Layout })

  self.width = width
  self.height = height
  self.picker = picker
  self.is_closed = false
  self:draw()

  -- vim.api.nvim_create_autocmd("WinResized", {
  --   group = vim.api.nvim_create_augroup("PickerLayoutAdjustSizeOnChange", { clear = true }),
  --   callback = function()
  --     if not self.is_closed then
  --       self:close()
  --       self:draw()
  --     end
  --   end,
  -- })

  return self
end


function Layout:close()
  self.is_closed = true
  for _, win in pairs({ self.rwin, self.qwin, self.pwin }) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.cmd.stopinsert()
  print("stopinsert")
end

function Layout:draw()
  self.is_closed = false
  -- Get terminal window size
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


  self.qwin = vim.api.nvim_open_win(self.picker.qbuf, true, {
    relative = 'editor',
    row = query_row_start,
    col = column_shift_to_center,
    width = results_and_query_win_width,
    height = query_win_height,
    border = "rounded",
  })

  self.rwin = vim.api.nvim_open_win(self.picker.rbuf, false, {
    relative = 'editor',
    row = results_row_start,
    col = column_shift_to_center,
    width = results_and_query_win_width,
    height = results_win_height,
    border = "rounded",
  })

  self.pwin = vim.api.nvim_open_win(self.picker.pbuf, false, {
    relative = 'editor',
    row = query_row_start,
    col = preview_column_shift,
    width = preview_win_width,
    height = preview_win_height,
    border = "rounded",
  })

  vim.cmd.startinsert()
end

return Layout
