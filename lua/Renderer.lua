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
  self.timer:start(10, 30, function()
    vim.schedule(function ()
      if self.timer:is_active() then
        self.picker.matcher.tick(10)
        self:render()
      end
    end)
  end)
end

function renderer:stop()
  self.timer:stop()
end

function renderer:render()
  vim.schedule(function()
    -- print("rendered " .. vim.uv.now())
    if not self.picker.layout.is_open then
      return
    end
    self.picker.query:update()
    self.picker.prompt:update()
    self.picker.previewer:update()
    -- for i, item in ipairs(items) do
    --   local indices = item[3]
    --   -- highlight.apply_indices(self.picker.prompt.buf, i - 1, indices)
    -- end
  end)
end

return M
