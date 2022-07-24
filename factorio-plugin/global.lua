--##

local util = require("factorio-plugin.util")

---Cache table for building the global name
local global_name_builder = {
  "__",
  "FallbackModName",
  "__",
  "global",
  "__",
}

---Rename `global` so we can tell them apart!
---@param uri string @ The uri of file
---@param text string @ The content of file
---@param diffs Diff[] @ The diffs to add more diffs to
---@param this_mod? string
local function replace(uri, text, diffs, this_mod)

  local scenario = uri:match("scenarios[\\/]([^\\/]+)[\\/]")--[[@as string?]]
  global_name_builder[2] = this_mod or "FallbackModName"
  global_name_builder[6] = scenario and scenario or nil
  global_name_builder[7] = scenario and "__" or nil

  ---Build the global name and replace any special characters with _
  local global_name = table.concat(global_name_builder, ""):gsub("[^a-zA-Z0-9_]","_")
  local global_matches = {} ---@type integer[]

  for start, finish in text:gmatch("%f[a-zA-Z0-9_]()global()%s*[=.%[]") --[[@as fun():integer, integer]] do
    global_matches[start] = finish
  end

  ---Remove matches that were `global` indexing into something (`T.global`)
  for start in text:gmatch("%.[^%S\n]*()global%s*[=.%[]") --[[@as fun():integer]] do
    global_matches[start] = nil
  end

  -- `_ENV.global` and `_G.global` now get removed because of this, we can add them back in
  -- with the code below, but it's a 66% performance cost increase for hardly any gain
  -- for start, finish in text:gmatch("_ENV%.%s*()global()%s*[=.%[]") do
  --   global_matches[start] = finish
  -- end
  -- for start, finish in text:gmatch("_G%.%s*()global()%s*[=.%[]") do
  --   global_matches[start] = finish
  -- end

  for start, finish in pairs(global_matches) do
    util.add_diff(diffs, start, finish, global_name)
  end

  --- and "define" it at the start of any file that used it
  if next(global_matches) then
    util.add_diff(diffs, 1, 1, global_name.."={}---@diagnostic disable-line:lowercase-global\n")
  end
end

return {
  replace = replace,
}
