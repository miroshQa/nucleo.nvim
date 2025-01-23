-- Singleton kind of. There is not reason to create multiple of it,
-- because we want set keymaps for buffer only once as well as create them (only on startup)
---@class PickerView
local self = {}

self.is_closed = true
self.qbuf = vim.api.nvim_create_buf(false, true)
self.rbuf = vim.api.nvim_create_buf(false, true)
self.pbuf = vim.api.nvim_create_buf(false, true)


function self.close()
  print("trying to close")
  vim.print({ self.rwin, self.qwin, self.pwin })
  self.is_closed = true
  for _, win in pairs({ self.rwin, self.qwin, self.pwin }) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.cmd.stopinsert()
end

---@param picker Picker
function self.render(picker)
  if self.is_closed then
    self._instantiate_windows()
    self.is_closed = false
  end

  self.ns_id = vim.api.nvim_create_namespace("MyNamespace")
  local values = picker.matcher:matched_items()
  -- NOTE: Should add only line highlight on <down> and <up>
  vim.schedule(function()
    vim.api.nvim_buf_set_lines(self.rbuf, 0, -1, false, values)
    if #values > 0 then
      local line = vim.api.nvim_buf_get_lines(self.rbuf, picker.selected, picker.selected + 1, false)[1]
      local ok, file = pcall(io.open, line, "r")
      if ok then
        local lines = vim.iter(file:lines()):totable()
        vim.api.nvim_buf_set_lines(self.pbuf, 0, -1, false, lines)
        vim.treesitter.start(self.pbuf, "lua")
      end
    end
  end)
  vim.cmd.startinsert()
end

function self.clear()
    vim.api.nvim_buf_set_lines(self.qbuf, 0, -1, false, {})
    vim.api.nvim_buf_set_lines(self.pbuf, 0, -1, false, {})
end

function self._instantiate_windows()
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


  self.qwin = vim.api.nvim_open_win(self.qbuf, true, {
    relative = 'editor',
    row = query_row_start,
    col = column_shift_to_center,
    width = results_and_query_win_width,
    height = query_win_height,
    border = "rounded",
  })

  self.rwin = vim.api.nvim_open_win(self.rbuf, false, {
    relative = 'editor',
    row = results_row_start,
    col = column_shift_to_center,
    width = results_and_query_win_width,
    height = results_win_height,
    border = "rounded",
  })

  self.pwin = vim.api.nvim_open_win(self.pbuf, false, {
    relative = 'editor',
    row = query_row_start,
    col = preview_column_shift,
    width = preview_win_width,
    height = preview_win_height,
    border = "rounded",
  })

  -- for _, win in ipairs({self.qwin, self.rwin, self.pwin}) do
  --   vim.wo[win].number = false
  --   vim.wo[win].relativenumber = false
  -- end

  vim.wo[self.rwin].cursorline = true
end

return self
