-- This file illustrate how you can use nucleo matcher in lua 

-- First you need to add path to your library
package.cpath = package.cpath .. ";./target/release/lib?.so"

---@type nucleo.Registry
local Registry = require("matchers_registry")
local id
local function create_and_drop()
  local matcher = Registry.new_nucleo_matcher()
  local n = 10000000
  local str = string.rep("a", 10)
  for _ = 1, n do
    matcher:add_item(str, str)
  end
  id = matcher:get_id()
  matcher = nil
  collectgarbage("collect")
  Registry.remove_matcher_by_id(id)
end

create_and_drop()
print("finished 1")
os.execute("sleep 1")

while true do
  -- just working further
  create_and_drop()
end
