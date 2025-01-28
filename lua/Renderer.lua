local highlight = require("utils.highlight")

local M = {}


---@class nucleo.Renderer
local renderer = {}

---@param picker nucleo.Picker
function M.new(picker)
  ---@class nucleo.Renderer
  local self = setmetatable({}, {__index = renderer})
  self.picker = picker
  return self
end


function renderer:start()
  self.timer = vim.uv.new_timer()
  self.timer:start(30, 30, function()
    vim.schedule(function ()
      -- print("render" .. vim.uv.now())
      self.picker.matcher.tick(10)
      self:render()
    end)
  end)
end

function renderer:stop()
  self.timer:stop()
end

local ns_id = vim.api.nvim_create_namespace('demo')
local mark_id = nil

function renderer:render()
  local prompt_win_size = vim.api.nvim_win_get_height(self.picker.layout.prompt_win)
  local cursor = vim.api.nvim_win_get_cursor(self.picker.layout.prompt_win)[0] or 0
  local items = self.picker.matcher.matched_items(0, cursor + prompt_win_size)
  local total = self.picker.matcher.item_count()
  local matched = self.picker.matcher.matched_item_count()

  if mark_id then
    vim.api.nvim_buf_del_extmark(self.picker.query.buf, ns_id, mark_id)
  end

  self.ns_id = vim.api.nvim_create_namespace("MyNamespace")
  mark_id = vim.api.nvim_buf_set_extmark(self.picker.query.buf, ns_id, 0, -1, {
    id = 1,
    virt_text = { { matched .. "/" .. total } },
    virt_text_pos = 'right_align',
  })

  local matchables = vim.iter(items):map(function(v) return v[1] end):totable()

  vim.schedule(function()
    -- print("rendered " .. vim.uv.now())
    vim.api.nvim_buf_clear_namespace(self.picker.prompt.buf, highlight.ns, 0, -1)
    vim.api.nvim_buf_set_lines(self.picker.prompt.buf, 0, -1, false, matchables)
    -- self.picker.previewer:display()
    -- for i, item in ipairs(items) do
    --   local indices = item[3]
    --   -- highlight.apply_indices(self.picker.prompt.buf, i - 1, indices)
    -- end
  end)
end

return M
