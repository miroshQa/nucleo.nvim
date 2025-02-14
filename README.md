# An experimental fuzzy finder powered by the Rust [Nucleo crate](https://crates.io/crates/nucleo) (implemented and used by helix editor), focused on maximum performance.

## WIP, DONT TRY TO USE IT, I WARNED YOU!

## NOTES
This project will probably never be complete but you can feel free to use
this for reference to see how you can build highly performant fuzzy finder
by integrating rust nucleo crate using C lua api via mlua rust crate

## Installation 
### 1. Install rust toolchain https://www.rust-lang.org/learn/get-started

### 2. Install with your package manager (Example with lazy.nvim)

```lua
{
  "miroshQa/nucleo.nvim",
  build = "cargo build --release",
  config = function()
    vim.keymap.set("n", "<leader>f", function() require("nucleo.files").run() end )
  end
}
```

- NOTE: To see the full power of this plugin you should use files picker on home or root directory
- NOTE: Building from source is currently the only available option.  
- NOTE: This plugin will probably only work for Linux at the moment.  
- NOTE: This plugin is 1% ready and is more of a proof of concept than a really working something  
- NOTE: There is and will be only lua api to call pickers
