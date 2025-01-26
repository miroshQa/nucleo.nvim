local M = {}

---@class nucleo.Source
local files = {}

function M.new()
---@class nucleo.Source
  local self = setmetatable({}, {__index = files})
  self.is_running = false
  self.fds = nil
  self.write_pipe = nil
  self.start_time = nil
  return self
end

-- TODO: REALLY MESSY CODE, need to clean up

local function start_stream(read_fds)
  -- Should write some utils function for this horro
  local libpath = debug.getinfo(1).source:match('@?(.*/)') .. "../../target/release/lib?.so"
  package.cpath = package.cpath .. ";" .. libpath
  local read_pipe = vim.uv.new_pipe(false)
  read_pipe:open(read_fds)

  local matcher = require("nucleo_matcher")
  local should_stop = false
  local stdout = vim.uv.new_pipe(false)
  local handle

  local function close_all_handles()
    for _, handle in ipairs({ stdout, handle, read_pipe }) do
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
    if data then
      for _, value in ipairs(vim.split(data, "\n")) do
        if should_stop then
          break
        end
        matcher.add_item(value, "")
      end
    end
  end)

  read_pipe:read_start(function(err, data)
    if err then
      print('Error reading from pipe:', err)
    elseif data == "stop" then
      print("Stop thread on demand")
      should_stop = true
      close_all_handles()
    end
  end)

  vim.uv.run("default")
end

function files:start(on_exit)
  self.fds = vim.uv.pipe({ nonblock = true }, { nonblock = true })
  self.write_pipe = vim.uv.new_pipe(false)
  self.write_pipe:open(self.fds.write)
  self.is_running = true
  self.start_time = vim.uv.now()
  local work = vim.uv.new_work(start_stream, function(...)
    self.is_running = false
    local finish_time = vim.uv.now() - self.start_time
    print("source took time: " .. finish_time)
    on_exit()
  end)
  work:queue(self.fds.read)
end

function files:stop()
  self.write_pipe:write("stop")
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
