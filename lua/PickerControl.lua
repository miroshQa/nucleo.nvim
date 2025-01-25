local state = require("NucleoState")
local PickerView = require("PickerView")
---@type Nucleo.Matcher
local matcher = require("nucleo_matcher")
print(vim.matcher)

local last_tick_time = nil

vim.api.nvim_create_autocmd("TextChangedI", {
  group = vim.api.nvim_create_augroup("UpdateResultsOnQueryChange", { clear = true }),
  callback = function()
    local now = vim.uv.now()
    if not last_tick_time or now - last_tick_time > 50 then
      local active = state.last_picker
      local pattern = vim.trim(vim.api.nvim_get_current_line())
      matcher.set_pattern(pattern)
      last_tick_time = now
    end
  end,
  buffer = PickerView.qbuf,
})

vim.keymap.set({ "i" }, "<down>", function()
  local active = state.last_picker
  local items_available = matcher.matched_item_count()
  if items_available == 0 then
    return
  end
  active.selected = math.min(active.selected + 1, items_available - 1)
  vim.api.nvim_buf_call(PickerView.rbuf, function()
    vim.cmd("norm! j")
  end)
  PickerView.render(active)
end, { buffer = PickerView.qbuf })

vim.keymap.set({ "i" }, "<up>", function()
  local active = state.last_picker
  local items_available = matcher.matched_item_count()
  if items_available == 0 then
    return
  end
  vim.api.nvim_buf_call(PickerView.rbuf, function()
    vim.cmd("norm! k")
  end)
  active.selected = math.max(active.selected - 1, 0)
  PickerView.render(active)
end, { buffer = PickerView.qbuf })

vim.keymap.set({ "i" }, "<CR>", function()
  local active = state.last_picker
  local line = vim.api.nvim_buf_get_lines(PickerView.rbuf, active.selected, active.selected + 1, false)[1]
  matcher.restart()
  PickerView:close()
  active.timer:stop()
  vim.cmd("e " .. line)
end, { buffer = PickerView.qbuf })

vim.keymap.set({ "i", "n" }, "<esc>", function()
  local active = state.last_picker
  matcher.restart()
  PickerView.close()
  active.timer:stop()
end, { buffer = PickerView.qbuf })
