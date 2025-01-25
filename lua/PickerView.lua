local matcher = require("nucleo_matcher")
local layout = require("layouts").default
local previewer = require("previewers.file")
-- Singleton kind of. There is not reason to create multiple of it,
-- because we want set keymaps for buffer only once as well as create them (only on startup)
---@class PickerView
local self = {}

self.is_closed = true
self.qbuf = vim.api.nvim_create_buf(false, true)
self.rbuf = vim.api.nvim_create_buf(false, true)
self.pbuf = vim.api.nvim_create_buf(false, true)
-- Not gonna use it to disable autocompletion; it seems like a legacy Vim feature that leads to
-- some quirks such as the c-w command not working and probably many more
-- vim.bo[self.qbuf].buftype = "prompt"

local ns_id = vim.api.nvim_create_namespace('demo')
local mark_id = nil
---@param picker Picker
function self.render(picker)
  if layout.is_closed then
    print("open new")
    layout:open({ qbuf = self.qbuf, pbuf = self.pbuf, rbuf = self.rbuf })
    vim.cmd.startinsert()
  end

  self.ns_id = vim.api.nvim_create_namespace("MyNamespace")
  local rwin_size = vim.api.nvim_win_get_height(layout.rwin)
  local values = matcher.matched_items(0, picker.selected + rwin_size)
  values = vim.iter(values):map(function(x)
    return x.matchable
  end):totable()
  local total = matcher.item_count()
  local matched = matcher.matched_item_count()

  if mark_id then
    vim.api.nvim_buf_del_extmark(self.qbuf, ns_id, mark_id)
  end

  mark_id = vim.api.nvim_buf_set_extmark(self.qbuf, ns_id, 0, -1, {
    id = 1,
    virt_text = { { matched .. "/" .. total } },
    virt_text_pos = 'right_align',
  })

  vim.schedule(function()
    -- print("redrawed" .. vim.uv.hrtime())
    vim.api.nvim_buf_set_lines(self.rbuf, 0, -1, false, values)
    if #values > 0 then
      local line = vim.api.nvim_buf_get_lines(self.rbuf, picker.selected, picker.selected + 1, false)[1]
      previewer.preview(self.pbuf, line)
    end
  end)
end

function self.clear()
  vim.api.nvim_buf_set_lines(self.qbuf, 0, -1, false, {})
  vim.api.nvim_buf_set_lines(self.pbuf, 0, -1, false, {})
end

return self
