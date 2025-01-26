local M = {}

M.ns = vim.api.nvim_create_namespace("random")

M.apply_indices = function(buf, line, indices)
  for _, col in ipairs(indices) do
    vim.api.nvim_buf_add_highlight(buf, M.ns, "Statement", line, col, col + 1)
  end
end

return M
