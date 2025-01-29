local M = {}

---@class nucleo.Picker.Query
local query = {}

---@param picker nucleo.Picker
function M.new(picker)
---@class nucleo.Picker.Query
  local self = setmetatable({}, { __index = query })
  self.buf = vim.api.nvim_create_buf(false, true)
  self.picker = picker
  self.mark_id = nil
  self.ns_id = nil

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

function query:update()
  local total = self.picker.matcher.item_count()
  local matched = self.picker.matcher.matched_item_count()

  if self.mark_id then
    vim.api.nvim_buf_del_extmark(self.picker.query.buf, self.ns_id, self.mark_id)
  end

  self.ns_id = vim.api.nvim_create_namespace("MyNamespace")
  self.mark_id = vim.api.nvim_buf_set_extmark(self.picker.query.buf, self.ns_id, 0, -1, {
    id = 1,
    virt_text = { { matched .. "/" .. total } },
    virt_text_pos = 'right_align',
})

end

return M
