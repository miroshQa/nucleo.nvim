local M = {}

---@class nucleo.Picker.Query
local Query = {}

---@param picker nucleo.Picker
function M.new(picker)
  ---@class nucleo.Picker.Query
  local self = setmetatable({}, { __index = Query })
  self.buf = vim.api.nvim_create_buf(false, true)
  self.picker = picker
  self.mark_id = nil
  self.ns_id = nil

  self.last_tick_time = 0
  self.au_on_change =  vim.api.nvim_create_augroup("UpdateResultsOnQueryChange", { clear = true })
  vim.api.nvim_create_autocmd("TextChangedI", {
    group = self.au_on_change,
    callback = function()
      local now = vim.uv.now()
      if now - self.last_tick_time > 10 then
        local pattern = vim.trim(vim.api.nvim_get_current_line())
        self.picker.matcher:set_pattern(pattern)
        self.last_tick_time = now
      end
    end,
    buffer = self.buf,
  })

  return self
end

function Query:destroy()
  vim.api.nvim_buf_delete(self.buf, { force = true })
  -- We must especially carefully in those cases, we need to
  -- remove all references to picker and allow to garbage collector clear
  -- all the picker components, and more importantly matcher on the rust side
  -- (will happen only if no references on lua side and also if
  --  matcher was removed from registry)
  vim.api.nvim_clear_autocmds({ group = self.au_on_change })
end

function Query:update()
  local total = self.picker.matcher:item_count()
  local matched = self.picker.matcher:matched_item_count()

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
