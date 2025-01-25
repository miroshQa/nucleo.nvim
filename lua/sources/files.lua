---@type Nucleo.Source
-- Why does this shit keep complain? I guess I declare annotations wrong. Need to study it
local files = {}
local is_running = false

local function start_stream()
  -- Should write some utils function for this horro
  local libpath = debug.getinfo(1).source:match('@?(.*/)') .. "../../nucleo_matcher/target/release/lib?.so"
  package.cpath = package.cpath .. ";" .. libpath

  local matcher = require("nucleo_matcher")
  local stdout = vim.uv.new_pipe(false)
  local handle

  handle = vim.uv.spawn('rg', {
    args = { "--files", "--no-messages", "--color", "never", "--hidden" },
    stdio = { nil, stdout, nil },
  }, function(code, signal)
      stdout:close()
      handle:close()
  end)

  vim.uv.read_start(stdout, function(err, data)
    assert(not err, err)
    if not data then
      return
    else
      for _, value in ipairs(vim.split(data, "\n")) do
        matcher.add_item_string(value)
      end
    end
  end)

  vim.uv.run("default")
end


function files.start(on_exit)
  if is_running then
    error("This source is already streaming")
  end
  is_running = true
  local work = vim.uv.new_work(start_stream, function (...)
    is_running = false
    on_exit()
  end)
  work:queue()
end

function files.stop()

  print("no implemented")
end


return files
