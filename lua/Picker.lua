---@class Picker
local Picker = {}


---comment
---@return Picker
---@param source Source
---@param matcher Matcher
---@param layout Layout
function Picker.new(source, matcher, layout)
  ---@class Picker
  local self = setmetatable({}, { __index = Picker })
  self.qbuf = vim.api.nvim_create_buf(false, false)
  self.rbuf = vim.api.nvim_create_buf(false, false)
  self.pbuf = vim.api.nvim_create_buf(false, false)
  self.matcher = matcher
  self.source = source
  self.layout = layout.new_helix_like(self)
  self.selected = 0 -- 0 means selected first item

  vim.api.nvim_create_autocmd("TextChangedI", {
    group = vim.api.nvim_create_augroup("UpdateResultsOnQueryChange", { clear = true }),
    callback = function()
      local pattern = vim.trim(vim.api.nvim_get_current_line())
      self:process_query(pattern)
    end,
    buffer = self.qbuf,
  })


  local screen_height = vim.o.lines
  local ns_id = vim.api.nvim_create_namespace("MyNamespace")

  local function render_selected()
    vim.api.nvim_buf_clear_namespace(self.rbuf, ns_id, 0, -1)
    vim.api.nvim_buf_add_highlight(self.rbuf, ns_id, "Cursor", self.selected, 0, -1)
    local line = vim.api.nvim_buf_get_lines(self.rbuf, self.selected, self.selected + 1, false)[1]
  end

  vim.keymap.set({ "i" }, "<down>", function()
    local items_available = self.matcher:matched_item_count()
    if items_available == 0 then
      return
    end
    self.selected = math.min(self.selected + 1, items_available - 1)
    render_selected()
  end, { buffer = self.qbuf })

  vim.keymap.set({ "i" }, "<up>", function()
    local items_available = self.matcher:matched_item_count()
    if items_available == 0 then
      return
    end
    self.selected = math.max(self.selected - 1, 0)
    render_selected()
  end, { buffer = self.qbuf })

  vim.keymap.set({ "i" }, "<CR>", function()
    local line = vim.api.nvim_buf_get_lines(self.rbuf, self.selected, self.selected + 1, false)[1]
    self.layout:close()
    vim.cmd("e " .. line)
  end, { buffer = self.qbuf })

  vim.keymap.set({ "i" }, "<esc>", function()
    self:destroy()
  end, { buffer = self.qbuf })


  self.source:get(function(items)
    if not items then
      return
    end
    self.matcher:add_items(items)
  end)

  return self
end

function Picker:destroy()
  self.layout:close()
  vim.api.nvim_buf_delete(self.qbuf, { force = true })
  vim.api.nvim_buf_delete(self.rbuf, { force = true })
  vim.api.nvim_buf_delete(self.pbuf, { force = true })
end

---@param query string
function Picker:process_query(query)
  self.matcher:reparse(query)
  local values = self.matcher:matched_items()
  vim.schedule(function()
    vim.api.nvim_buf_set_lines(self.rbuf, 0, -1, false, values)
  end)
end

return Picker
