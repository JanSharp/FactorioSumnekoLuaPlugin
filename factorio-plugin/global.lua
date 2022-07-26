--##

local util = require("factorio-plugin.util")
local table_concat = table.concat

---Cache table for building the global name
local global_class_builder = { " ---@type ", "", ".", "", "", "global","\n" }
local global_name_builder = { "__", "FallbackModName", "__", "global" }

---Rename `global` so we can tell them apart!
---@api Move settings to the top scope of the file if sandboxing is added.
---@param uri string @ The uri of file
---@param text string @ The content of file
---@param diffs Diff.ArrayWithCount @ The diffs to add more diffs to
---@param this_mod? string
---@param settings fplugin.settings
local function replace(uri, text, diffs, this_mod, settings)
  local scenario = uri:match("scenarios[\\/]([^\\/]+)[\\/]") --[[@as string?]]
  local as_class = settings.global_as_class  ---@api Move to top scope if sandboxing is added.

  ---Build the global name and replace any special characters with _
  global_name_builder[2] = this_mod or settings.fallback_mod_name
  global_name_builder[5] = scenario and "__" or ""
  global_name_builder[6] = scenario or ""
  global_name_builder[7] = scenario and "__" or ""
  local global_name = table_concat(global_name_builder, ""):gsub("[^a-zA-Z0-9_]", "_")

  local global_matches = {} ---@type integer[]

  ---Find all matches for global ---@todo Assignment to global disable warning
  for start, finish in text:gmatch("%f[a-zA-Z0-9_]()global()%s*[=.%[]") --[[@as fun():integer, integer]]do
    global_matches[start] = finish
  end

  ---Remove matches that were `global` indexing into something (`T.global`)
  for dot_pos, start in text:gmatch("()%.[^%S\n]*()global%s*[=.%[]") --[[@as fun():integer, integer]]do
      if text:sub(dot_pos - 1, dot_pos - 1) ~= "." then
      global_matches[start] = nil
      end
  end

  -- `_ENV.global` and `_G.global` now get removed because of this, we can add them back in
  -- with the code below, but it's a 66% performance cost increase for hardly any gain
  -- for start, finish in text:gmatch("_ENV%.%s*()global()%s*[=.%[]") do
  --   global_matches[start] = finish
  -- end
  -- for start, finish in text:gmatch("_G%.%s*()global()%s*[=.%[]") do
  --   global_matches[start] = finish
  -- end

  --- Store the first diff position
  local first_diff_position = diffs.count + 1
  ---Replace all matching instances of `global` with the new global name
  for start, finish in pairs(global_matches) do
    util.add_diff(diffs, start, finish, global_name)
  end

  --- and "define" it at the start of any file that used it
  if next(global_matches) then
    if as_class then
      global_class_builder[2] = this_mod
      global_class_builder[4] = scenario or ""
      global_class_builder[5] = scenario and "." or ""
    end

    local class_str = as_class and table_concat(global_class_builder, "")
    ---Putting it in _G. prevents the need to disable lowecase-global
    local global_replacement = { "_G.", global_name, " = {}", class_str or "\n"}

    util.add_diff(diffs, 1, 1, table_concat(global_replacement, ""))

    -- Account for situations where `global` is used at the begining of the first line.
    local diff = diffs[first_diff_position]
    if diff.start == 1 then
      diffs[first_diff_position] = diffs[diffs.count]
      diffs[diffs.count] = diff
    end
  end
end

return replace
