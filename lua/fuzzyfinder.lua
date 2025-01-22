local Picker = require("Picker")
local Layout = require("Layout")
local Matcher = require("Matcher")
local FilesSource = require("FilesSource")

local function fuzzyFinder()
  local source = FilesSource.new()
  local matcher = Matcher.new()
  local picker = Picker.new(source, matcher, Layout)
end

return fuzzyFinder
