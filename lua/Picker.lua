---@class Picker
local Picker = {}

---comment
---@return Picker
---@param source Source
---@param matcher Matcher
function Picker.new(source, matcher)
  ---@class Picker
  local self = setmetatable({}, { __index = Picker })
  self.matcher = matcher
  self.source = source
  self.selected = 0 -- 0 means selected first item

  local function work_callback()
    local libpath = debug.getinfo(1).source:match('@?(.*/)') .. "../nucleo_matcher/target/release/lib?.so"
    package.cpath = package.cpath .. ";" .. libpath

    local matcher = require("nucleo_matcher")
    local should_live = true
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
        matcher.add_items_strings_tbl(vim.split(data, "\n"))
      end
    end)

    vim.uv.run("default")

  end

  local work = vim.uv.new_work(work_callback, function (...)
    print("work exit")
  end)
  work:queue()

  return self
end

return Picker
