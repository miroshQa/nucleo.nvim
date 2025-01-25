---@class layout
---@field open fun(qbuf, rbuf, pbuf)
---@field close fun()
---@field qwin number
---@field rwin number
---@field pwin number
---@field is_active boolean

local pickers = {
  files = {
    layout = nil,
    actions = {
      ["<CR>"] = function() end
    },
    entry_formatter = function() end
  },
}

return pickers
