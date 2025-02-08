local common_actions = require "common_actions"

local config = {}


config.pickers = {
  default_layout = require("layouts.classic").new(),
  default_mappings = {
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
}

return config
