local common_actions = require "sources.common_actions"
local libpath = debug.getinfo(1).source:match('@?(.*/)') .. "./../target/release/lib?.so"
package.cpath = package.cpath .. ";" .. libpath

local config = require("config")
local matcher = require("nucleo_matcher")
local Picker = require("Picker")
local M = {}

local ClassicLayoutFabric = require("layouts.classic")

function M.find_files()
  matcher.restart()
  local source = require("sources.files").new()
  local layout = require("layouts.classic").new()
  local mappings = {
    i = {
      ["<down>"] = common_actions.down,
      ["<up>"] = common_actions.up,
      ["<esc>"] = common_actions.hide,
      ["<CR>"] = require("sources.files").actions.select_entry,
    }
  }
  local picker = Picker.new({source = source, layout = layout, matcher = matcher, mappings = mappings})
  picker:run()
end

function M.last_picker()
end

---@class nucleo.find_buffers
M.find_buffers = {
  ---@class nucleo.find_buffers.spec
  spec = {
    layout = ClassicLayoutFabric,
  },
  ---@param self nucleo.find_buffers
  ---@param opts nucleo.find_buffers.spec
  run = function(self, opts)
    -- local picker = Picker.new(config.pickers.find_files)
    print(opts)
  end
}

-- M.find_buffers:go("aboba")
M.find_buffers:run()


return M
