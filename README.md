# An experimental fuzzy finder powered by the Rust [Nucleo crate](https://crates.io/crates/nucleo) (implemented and used by helix editor), focused on maximum performance.

## WIP, DONT TRY TO USE IT, I WARNED YOU!

## Installation 
### 1. Install rust toolchain https://www.rust-lang.org/learn/get-started

### 2. Install with your package manager (Example with lazy.nvim)

```lua
{
  "miroshQa/nucleo.nvim",
  build = "cd nucleo_matcher ; cargo build --release",
  config = function()
    vim.keymap.set("n", "<leader>t", function() require("nucleo").files() end )
  end
}

```
- NOTE: Building from source is currently the only available option.  
- NOTE: This plugin will probably only work for Linux at the moment.  
- NOTE: This plugin is 1% ready and is more of a proof of concept than a really working something  
