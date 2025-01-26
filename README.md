# An experimental fuzzy finder powered by the Rust [Nucleo crate](https://crates.io/crates/nucleo) (implemented and used by helix editor), focused on maximum performance.

## WIP, DONT TRY TO USE IT, I WARNED YOU!

## Installation 
### 1. Install rust toolchain https://www.rust-lang.org/learn/get-started

### 2. Install with your package manager (Example with lazy.nvim)

```lua
{
  "miroshQa/nucleo.nvim",
  build = "cargo build --release",
  config = function()
    -- Some essential keymaps
    vim.keymap.set("n", "<leader>f", function() require("nucleo").files() end )
    -- commented keymaps currently not implemented yet
    -- vim.keymap.set("n", "<leader>/", function() require("nucleo").live_grep() end )
    -- vim.keymap.set("n", "<leader>'", function() require("nucleo").last_picker() end )
    --
    -- vim.keymap.set("n", "<leader>b", function() require("nucleo").buffers() end )
    -- vim.keymap.set("n", "<leader>j", function() require("nucleo").jumplist() end )
    -- vim.keymap.set("n", "<leader>g", function() require("nucleo").git_changed() end )
    -- vim.keymap.set("n", "<leader>s", function() require("nucleo").lsp_symbols() end )
    -- vim.keymap.set("n", "<leader>S", function() require("nucleo").lsp_workspace_symbols() end )
    -- vim.keymap.set("n", "<leader>i", function() require("nucleo").lsp_diagnostics() end )
    -- vim.keymap.set("n", "<leader>I", function() require("nucleo").lsp_workspace_diagnostics() end )
  end
}

```
- NOTE: Building from source is currently the only available option.  
- NOTE: This plugin will probably only work for Linux at the moment.  
- NOTE: This plugin is 1% ready and is more of a proof of concept than a really working something  
