--##

local util = require("factorio-plugin.util")

--[[
  Looks for patterns similar to the following:
  -  `require("__mod_a__/test")`
  -  `require("__mod_a__.test")`
  -  `require '__mod_a__.test'`
  -  `require "__mod_a__/test"`
  And replaces `__mod_a__` with `mod_a` to allow the lua language server to locate the file.
]]
---@param _ string @ The uri of file
---@param text string @ The content of file
---@param diffs Diff[] @ The diffs to add more diffs to
local function replace(_, text, diffs)
  for start, name, finish in
    text:gmatch("require%s*%(?%s*['\"]()(.-)()['\"]%s*%)?")--[[@as fun(): integer, string, integer]]
  do
    local original_name = name

    ---Convert the mod name prefix if there is one
    name = name:gsub("^__(.-)__", "%1")

    if name ~= original_name then
      util.add_diff(diffs, start, finish, name)
    end
  end
end

return replace
