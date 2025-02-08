local M = {}

---@class nucleo.Source: nucleo.NewThreadProc.components
local NewThreadProc = {}

---@class nucleo.NewThreadProc.components
---@field spawn_args string[]
---@field spawn_cmd string


---@param components nucleo.NewThreadProc.components
function M.new(components)
  ---@class nucleo.Source
  local self = setmetatable(components, { __index = NewThreadProc })
  return self
end

local function start_stream(matcher_id, spawn_args, spawn_cmd)
  -- Should write some utils function for this horro
  local libpath = debug.getinfo(1).source:match('@?(.*/)') .. "../../target/release/lib?.so"
  package.cpath = package.cpath .. ";" .. libpath
  spawn_args = vim.json.decode(spawn_args)

  local matcher = require("matchers_registry").get_matcher_by_id(matcher_id)
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
  handle = vim.uv.spawn(spawn_cmd, {
    args = spawn_args,
    stdio = { nil, stdout, nil },
  }, function(code, signal)
    close_all_handles()
  end)

  local prev = nil
  vim.uv.read_start(stdout, function(err, data)
    assert(not err, err)
    if not data then
      return
    end

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
        local status = matcher:add_item(line, "")
        if status == 1 then
          return close_all_handles()
        end
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

  vim.uv.run("default")
end

function NewThreadProc:start(matcher, on_exit)
  local work = vim.uv.new_work(start_stream, function(...) on_exit() end)
  work:queue(matcher:get_id(), vim.json.encode(self.spawn_args), self.spawn_cmd)
end

return M
