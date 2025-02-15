local M = {}

---@class nucleo.Source
---@field start fun(self, matcher: nucleo.Matcher): thread

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
---@return thread
local function start_stream(matcher, streamer)
  local stdout = assert(vim.uv.new_pipe(false))
  local handle

  local function close_all_handles()
    for _, h in ipairs({ stdout, handle }) do
      if h:is_active() then
        h:close()
      end
    end
  end

  local process_exited = false
  ---@diagnostic disable-next-line: missing-fields
  handle = vim.uv.spawn(streamer.spawn_cmd, {
    args = streamer.spawn_args,
    stdio = { nil, stdout, nil },
  }, function(code, signal)
    process_exited = true
    close_all_handles()
  end)

  local prev = nil
  local queue = {}
  local queue_ptr = 1
  local process = coroutine.create(function()
    while true do
      ::start::
      if process_exited and queue_ptr == #queue + 1 then
        break
      elseif queue_ptr == #queue + 1 then
        coroutine.yield()
        goto start
      end

      local start = vim.uv.now()
      local from = 1
      local data = queue[queue_ptr]
      while from <= #data do
        if vim.uv.now() - start > 10 then
          coroutine.yield()
        end
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
      queue_ptr = queue_ptr + 1
    end
  end)

  vim.uv.read_start(stdout, function(err, data)
    assert(not err, err)
    if not data then
      return
    end
    table.insert(queue, data)
  end)

  return process
end

---@return thread
function MainThreadProc:start(matcher)
  return start_stream(matcher, self)
end

return M
