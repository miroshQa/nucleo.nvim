---@type nucleo.layout
local layout = {}

function layout.new()
  local self = setmetatable({}, { __index = layout })
  self.is_closed = true
  return self
end

function layout:close()
  for _, win in pairs({ self.rwin, self.qwin, self.pwin }) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.cmd.stopinsert()
  self.is_closed = true
end

function layout:open(ctx)
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
  self.qwin = vim.api.nvim_open_win(ctx.qbuf, true, {
    relative = 'editor',
    row = query_row_start,
    col = column_shift_to_center,
    width = results_and_query_win_width,
    height = query_win_height,
    border = "rounded",
  })

  self.rwin = vim.api.nvim_open_win(ctx.rbuf, false, {
    relative = 'editor',
    row = results_row_start,
    col = column_shift_to_center,
    width = results_and_query_win_width,
    height = results_win_height,
    border = "rounded",
  })

  self.pwin = vim.api.nvim_open_win(ctx.pbuf, false, {
    relative = 'editor',
    row = query_row_start,
    col = preview_column_shift,
    width = preview_win_width,
    height = preview_win_height,
    border = "rounded",
  })

  -- for _, win in ipairs({opts.qwin, self.rwin, self.pwin}) do
  --   vim.wo[win].number = false
  --   vim.wo[win].relativenumber = false
  -- end

  vim.wo[self.rwin].cursorline = true
  vim.wo[self.rwin].wrap = false
  vim.print({ self.rwin, self.qwin, self.pwin })
  self.is_closed = false
end

return layout
