local M = {}

---@class nucleo.Source
---@field start fun(self, matcher: nucleo.Matcher, on_exit: fun())

---@class nucleo.MainThreadProc: nucleo.MainThreadProc.components
local MainThreadProc = {}

---@class nucleo.MainThreadProc.components
---@field spawn_args string[]
---@field spawn_cmd string


---@param components nucleo.MainThreadProc.components
function M.new(components)
  ---@class nucleo.MainThreadProc
  local self = setmetatable(components, { __index = MainThreadProc })
  return self
end

---@param streamer nucleo.MainThreadProc
local function start_stream(matcher, streamer, on_exit)
  local stdout = assert(vim.uv.new_pipe(false))
  local handle

  local function close_all_handles()
    for _, h in ipairs({ stdout, handle }) do
      if h:is_active() then
        h:close()
      end
    end
  end

  ---@diagnostic disable-next-line: missing-fields
  handle = vim.uv.spawn(streamer.spawn_cmd, {
    args = streamer.spawn_args,
    stdio = { nil, stdout, nil },
  }, function(code, signal)
    matcher = nil
    close_all_handles()
    on_exit()
  end)

  local prev = nil
  local counter = 0
  local function process(data)
    counter = counter + 1
    --thx folke for this code
    local from = 1
    while from <= #data do
      local nl = data:find("\n", from, true)
      if nl then
        local cr = data:byte(nl - 1, nl - 1) == 13 -- \r
        local line = data:sub(from, nl - (cr and 2 or 1))
        if prev then
          line, prev = prev .. line, nil
        end
        matcher:add_item(line, "")
        from = nl + 1
      elseif prev then
        prev = prev .. data:sub(from)
        break
      else
        prev = data:sub(from)
        break
      end
    end
  end

  vim.uv.read_start(stdout, function(err, data)
    assert(not err, err)
    if not data then
      return
    end
    process(data)
  end)
end

function MainThreadProc:start(matcher, on_exit)
  print("streaming from main thread")
  start_stream(matcher, self, on_exit)
end

return M
