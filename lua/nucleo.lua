local common_actions = require "sources.common_actions"
local libpath = debug.getinfo(1).source:match('@?(.*/)') .. "./../target/release/lib?.so"
package.cpath = package.cpath .. ";" .. libpath

local config = require("config")
local Picker = require("Picker")
local M = {}
M.pickers = {}
M.pickers.default_layout = require("layouts.classic").new()
M.pickers.default_mappings = {
  i = {
    ["<down>"] = common_actions.down,
    ["<up>"] = common_actions.up,
    ["<esc>"] = common_actions.hide,
    ["<CR>"] = common_actions.open,
    -- ["<C-d>"] = common_actions.preview_down,
    -- ["<C-u>"] = common_actions.preview_up,
    -- ["<C-q>"] = common_actions.send_all_to_quickfixlist,
    -- ["<CR>"] = common_actions.open_cur_buf,
    -- ["<C-v>"] = common_actions.open_vsplit,
    -- ["<C-s>"] = common_actions.open_split,
  }
}

function M.find_files()
  print("trying to create matcher")
  local matcher_id = require("nucleo_matcher").new_nucleo_matcher()
  print("id is: " .. matcher_id)
  print("After create")
  local source = require("sources.files").new()
  local layout = M.pickers.default_layout
  local picker = Picker.new({
    source = source,
    layout = layout,
    matcher_id = matcher_id,
    mappings = M.pickers.default_mappings,
  })
  picker:run()
end

-- function M.find_buffers()
--   matcher.restart()
--   local source = require("sources.buffers").new()
--   local layout = M.pickers.default_layout:clone()
--   local picker = Picker.new({
--     source = source,
--     layout = layout,
--     matcher = matcher,
--     mappings = M.pickers.default_mappings,
--   })
--   picker:run()
-- end

function M.last_picker()
end

-- ---@class nucleo.find_buffers
-- M.find_buffers = {
--   layout = M.pickers.default_layout:clone(),
--   run = function(self, opts)
--     -- local picker = Picker.new(config.pickers.find_files)
--     print(opts)
--   end
-- }
--


return M
