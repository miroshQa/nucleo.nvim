local M = {}

---@class nucleo.Source
local files = {}

function M.new()
---@class nucleo.Source
  local self = setmetatable({}, {__index = files})
  self.is_running = false
  return self
end


local function start_stream(matcher_id)
  -- Should write some utils function for this horro
  local libpath = debug.getinfo(1).source:match('@?(.*/)') .. "../../target/release/lib?.so"
  package.cpath = package.cpath .. ";" .. libpath

  local matcher = require("matchers_registry").get_matcher_by_id(matcher_id)
  local stdout = vim.uv.new_pipe(false)
  local handle

  local function close_all_handles()
    for _, handle in ipairs({ stdout, handle }) do
      if handle:is_active() then
        handle:close()
      end
    end
  end

  handle = vim.uv.spawn('rg', {
    args = { "--files", "--no-messages", "--color", "never", "--hidden" },
    stdio = { nil, stdout, nil },
  }, function(code, signal)
    close_all_handles()
  end)

  vim.uv.read_start(stdout, function(err, data)
    assert(not err, err)

    local status
    if data then
      for _, value in ipairs(vim.split(data, "\n")) do
        status = matcher:add_item(value, "")
        if status == 1 then
          close_all_handles()
          break
        end
      end
    end
  end)

  vim.uv.run("default")
end

function files:start(matcher)
  self.is_running = true
  self.start_time = vim.uv.now()
  local work = vim.uv.new_work(start_stream, function(...)
    self.is_running = false
    local finish_time = vim.uv.now() - self.start_time
    print("source took time: " .. finish_time)
    -- on_exit()
  end)
  work:queue(matcher:get_id())
end

M.actions = {
  ---@param picker nucleo.Picker
  select_entry = function(picker)
    local cursor = vim.api.nvim_win_get_cursor(picker.layout.prompt_win)[1] - 1
    local line = vim.api.nvim_buf_get_lines(picker.prompt.buf, cursor, cursor + 1, false)[1]
    picker.renderer:stop()
    picker.layout:close()
    vim.cmd("e " .. line)
  end,
}

return M
