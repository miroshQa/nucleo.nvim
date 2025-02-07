package.cpath = package.cpath .. ";./target/release/lib?.so"

local matcher = require("nucleo_matcher")
for i = 1, 10e6 do
  matcher.add_item("", "")
end
