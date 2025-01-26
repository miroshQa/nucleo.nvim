package.cpath = package.cpath .. ";./target/release/lib?.so"

local matcher = require("nucleo_matcher")
matcher.add_item("test", "")
matcher.add_item("alvalue", "")
matcher.add_item("valuevaluevalue", "")
matcher.add_item("aaaaaagl", "")
print(matcher.item_count())
print(matcher.matched_item_count())
matcher.set_pattern("al")
matcher.tick(10)
print(matcher.item_count())
print(matcher.matched_item_count())
local matched = matcher.matched_items(0, 100000)
vim.print(matched)

matcher.restart()
print(matcher.item_count())

-- To test it just open neovim in this directory, visually select code and type ":lua"
