local M = {}

---@class
local buffers = {}

function M.new()
  local self = setmetatable({}, {__index = buffers})
  return self
end

---@param matcher nucleo.Matcher
function buffers:start(matcher)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if name ~= "" then
      matcher:add_item(name, "")
    end
  end
end

function buffers:stop()
end

return M
