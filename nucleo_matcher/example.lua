package.cpath = package.cpath .. ";./target/release/lib?.so"

-- require("nucleo_matcher").hello("value")
-- require("nucleo_matcher").print_table({"print table", "bye bye"})
local matcher = require("nucleo_matcher")
matcher.add_items({"miron", "aboba", "veron"})
print(matcher.item_count())
matcher.set_pattern("o")
matcher.reparse()
print(matcher.item_count())
print(matcher.matched_item_count())
local matched = matcher.matched_items(0, 100000)

print("matched:")
for _, value in ipairs(matched) do
  print(value)
end

matcher.restart()
print(matcher.item_count())
