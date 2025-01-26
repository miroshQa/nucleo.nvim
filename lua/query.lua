local M = {}

local query = {}

function M.new(picker)
  local self = setmetatable({}, { __index = query })
  self.buf = vim.api.nvim_create_buf(false, true)
  self.picker = picker

  self.last_tick_time = 0
  vim.api.nvim_create_autocmd("TextChangedI", {
    group = vim.api.nvim_create_augroup("UpdateResultsOnQueryChange", { clear = true }),
    callback = function()
      local now = vim.uv.now()
      if now - self.last_tick_time > 10 then
        local pattern = vim.trim(vim.api.nvim_get_current_line())
        self.picker.matcher.set_pattern(pattern)
        self.last_tick_time = now
      end
    end, buffer = self.buf,
  })

  return self
end

function query:destroy()
  vim.api.nvim_buf_delete(self.buf, {force = true})
end

return M
