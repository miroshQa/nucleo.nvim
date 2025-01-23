local state = require("NucleoState")
local PickerView = require("PickerView")
local timer = vim.uv.new_timer()

vim.api.nvim_create_autocmd("TextChangedI", {
  group = vim.api.nvim_create_augroup("UpdateResultsOnQueryChange", { clear = true }),
  callback = function()
    if timer:is_active() then
      timer:stop()
    end

    timer:start(30, 0, function()
      vim.schedule(function ()
        local active = state.last_picker
        local pattern = vim.trim(vim.api.nvim_get_current_line())
        active.matcher.set_pattern(pattern)
        active.matcher.reparse()
        PickerView.render(active)
      end)
    end)
  end,
  buffer = PickerView.qbuf,
})

vim.keymap.set({ "i" }, "<down>", function()
  local active = state.last_picker
  local items_available = active.matcher.matched_item_count()
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
  local items_available = active.matcher.matched_item_count()
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
  PickerView:close()
  vim.cmd("e " .. line)
end, { buffer = PickerView.qbuf })

vim.keymap.set({ "i", "n" }, "<esc>", function()
  PickerView.close()
end, { buffer = PickerView.qbuf })
