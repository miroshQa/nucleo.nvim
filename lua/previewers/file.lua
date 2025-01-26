---@class nucleo.Previewer
local previewer = {}

function previewer.preview(pbuf, entry)
  local stat = vim.uv.fs_stat(entry)
  if not stat or stat.type == "directory" then
    return
  end
  local ok, file = pcall(io.open, entry, "r")
  local ft = vim.filetype.match({ filename = entry })
  if ok and file then
    local lines = vim.iter(file:lines()):totable()
    vim.api.nvim_buf_set_lines(pbuf, 0, -1, false, lines)
    pcall(vim.treesitter.start, pbuf, ft)
  end
end

return previewer
