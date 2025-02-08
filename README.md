# An experimental fuzzy finder powered by the Rust [Nucleo crate](https://crates.io/crates/nucleo) (implemented and used by helix editor), focused on maximum performance.

## WIP, DONT TRY TO USE IT, I WARNED YOU!

## PROJECT NOTES FOR ME
- We should reuse existing buffers for pickers instead creating new one each time 

## Installation 
### 1. Install rust toolchain https://www.rust-lang.org/learn/get-started

### 2. Install with your package manager (Example with lazy.nvim)

```lua
{
  "miroshQa/nucleo.nvim",
  build = "cargo build --release",
  config = function()
    vim.keymap.set("n", "<leader>f", function() require("pickers.files").run() end )
  end
}
```
- NOTE: Building from source is currently the only available option.  
- NOTE: This plugin will probably only work for Linux at the moment.  
- NOTE: This plugin is 1% ready and is more of a proof of concept than a really working something  
- NOTE: There is and will be only lua api to call pickers
