local M = {}

---@type nucleo.Source
local files = {}

function M.new()
  ---@class nucleo.Source
  local self = setmetatable({}, { __index = files })
  return self
end

local function start_stream(matcher, on_exit)
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
  handle = vim.uv.spawn('rg', {
    args = { "--files", "--no-messages", "--color", "never", "--hidden" },
    stdio = { nil, stdout, nil },
  }, function(code, signal)
    close_all_handles()
    on_exit()
  end)

  local prev ---@type string?
  vim.uv.read_start(stdout, function(err, data)
    assert(not err, err)
    if not data then
      return
    end

    local from = 1
    while from <= #data do
      local nl = data:find("\n", from, true)
      if nl then
        local cr = data:byte(nl - 1, nl - 1) == 13   -- \r
        local line = data:sub(from, nl - (cr and 2 or 1))
        if prev then
          line, prev = prev .. line, nil
        end
        local status = matcher.add_item(line, "")
        from = nl + 1
      elseif prev then
        prev = prev .. data:sub(from)
        break
      else
        prev = data:sub(from)
        break
      end
    end

  end)
end

function files:start(matcher, on_exit)
  start_stream(matcher, on_exit)
end

return M
