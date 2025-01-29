
local M = {}

---@class nucleo.Picker.Previewer
local previewer = {}

---@param picker nucleo.Picker
function M.new(picker)
---@class nucleo.Picker.Previewer
  local self = setmetatable({}, { __index = previewer })
  self.buf = vim.api.nvim_create_buf(false, true)
  self.picker = picker
  -- self.formatter = nil
  return self
end

function previewer:destroy()
  vim.api.nvim_buf_delete(self.buf, {force = true})
end

function previewer:update()
  -- specific code for find_files picker, need to abstract this stuff 
  local matched_items_count = self.picker.matcher.matched_item_count()
  local cursor = self.picker.prompt.selected
  if matched_items_count <= cursor then
    return
  end
  local item = self.picker.matcher.get_matched_item(cursor)
  local file_name = item[1]
  local stat = vim.uv.fs_stat(file_name)
  if not stat or stat.type == "directory" or stat.size > 100 * 1024 then
    return
  end
  local ok, file = pcall(io.open, file_name, "r")
  local ft = vim.filetype.match({ filename = file_name })
  if ok and file then
    local lines = vim.iter(file:lines()):totable()
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
    pcall(vim.treesitter.start, self.buf, ft)
  end
end

return M
