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
        local running, changed = self.picker.matcher:tick(10)
        if changed then
          self:render()
        end
      end
    end)
  end)
end

function renderer:stop()
  if self.timer:is_active() then
    self.timer:stop()
  end
end

function renderer:render()
  vim.schedule(function()
    if not self.picker.layout.is_open then
      return
    end
    self.picker.query:update()
    self.picker.prompt:update()
    self.picker.previewer:update()
  end)
end

return M
