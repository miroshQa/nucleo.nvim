---@type nucleo.Source
-- Why does this shit keep complain? I guess I declare annotations wrong. Need to study it
local files = {}
local is_running = false
local fds = nil
local write_pipe = nil
local start_time = nil

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


function files.start(on_exit)
  fds = vim.uv.pipe({ nonblock = true }, { nonblock = true })
  write_pipe = vim.uv.new_pipe(false)
  write_pipe:open(fds.write)
  -- if is_running then
  --   error("This source is already streaming")
  -- end
  is_running = true
  start_time = vim.uv.now()
  local work = vim.uv.new_work(start_stream, function(...)
    is_running = false
    local finish_time = vim.uv.now() - start_time
    print("source took time: " .. finish_time)
    on_exit()
  end)
  work:queue(fds.read)
end

function files.stop()
  write_pipe:write("stop")
end

return files
