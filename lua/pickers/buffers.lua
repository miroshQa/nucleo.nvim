require("nucleo") -- just hack for now, need to fix it
local Picker = require("Picker")
local Registry = require("matchers_registry")
local config = require("config")

local M = {}

local BuffersSource = {}

function BuffersSourceNew()
  local self = setmetatable({}, {__index = BuffersSource})
  return self
end

---@param matcher nucleo.Matcher
function BuffersSource:start(matcher)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if name ~= "" then
      matcher:add_item(name, "")
    end
  end
end

function M.run()
  local matcher = Registry.new_nucleo_matcher()
  local source = BuffersSourceNew()
  local layout = config.pickers.default_layout:clone()
  local picker = Picker.new({
    source = source,
    layout = layout,
    matcher = matcher,
    mappings = M.pickers.default_mappings,
  })
  picker:run()
end

return M
