local config = require("config")
local Picker = require("Picker")
local Registry = require("Registry")

local M = {}

function M.run()
  local matcher = Registry.new_nucleo_matcher()
  local source = require("sources.MainThreadProc").new({
    spawn_cmd = "rg",
    spawn_args = { "--files", "--no-messages", "--color", "never", "--hidden" },
  })
  local picker = Picker.new({
    source = source,
    layout = config.pickers.default_layout:clone(),
    matcher = matcher,
    mappings = config.pickers.default_mappings,
  })
  picker:run()
end

return M
