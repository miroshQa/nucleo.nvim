---@class Source
local Files = {}

---@class Source
function Files.new()
  local self = setmetatable({}, { __index = Files })
  return self
end

---Starting items stream
---@param callback fun(items: string[])
function Files:get(callback)
  local stdout = vim.uv.new_pipe(false)
  local handle

  handle = vim.uv.spawn('rg', {
    args = { "--files", "--no-messages", "--color", "never" },
    stdio = { nil, stdout, nil },
  }, function(code, signal)
    stdout:close()
    handle:close()
  end)

  vim.uv.read_start(stdout, function(err, data)
    assert(not err, err)
    if not data then
      callback(nil)
    else
      callback(vim.split(data, "\n"))
    end
  end)
end

return Files
