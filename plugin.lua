--##
---cSpell:ignore userdata, nups, nparams

-- (this should probably be in some better location, maybe the readme? i'm not sure)
-- what do the different prefixes for gmatch results mean:
-- s = start, f = finish, p = position, no prefix = an actual string capture

-- sample Arguments:
-- "Lua.runtime.pluginArgs": ["--mode mods", "--global-as-class", "--no-class-warning", "--disable event", "--disable require"]

---Dev Notes: confirm "path/to/lua-language-server/script/", in Lua.Workspace.Library for completions

local scp = require("workspace.scope")

local require_module = require("factorio-plugin.require")
local global = require("factorio-plugin.global")
local remote = require("factorio-plugin.remote")
local on_event = require("factorio-plugin.on-event")

local furi = select(2, ...)
local plugin_args = select(3, ...)
print("Plugin Loaded:", furi)

local settings = require("factorio-plugin.settings")(furi, plugin_args)

--[[
  In `folder` mode cache and return the mod name.\
  In `mods` mode the mod name changes depending on the file being edited so it can't be cached in `settings.mod_name`.\
  For example in the file `C:\\Factorio-Game\\MyModsFolder\\MyMod\\control.lua`
  The mod_root would be `MyModsFolder` which can be cached as `settings.mod_root` and `MyMod` would be the mod_name which can't be cached.
]]
---@param scope scope
---@param file_uri string
local function get_mod_name(scope, file_uri)
  -- local settings = scope:get("pluginInterface").settings
  -- if settings.mod_name then return settings.mod_name end

  local mode = settings.mode
  local mod_name ---@type string?

  ---Cache the mod name in folder mode
  if mode == "folder" then
    mod_name = scope.uri:match("[^/\\]+$") --[[@as string?]]
    settings.mod_name = mod_name
    return mod_name
  end

  if mode == "mods" then
    -- Cache The root folder path
    local root = settings.mods_root
    if not root then
      -- get the end folder of root path
      root = scope.uri:match("[^/\\]+$")
      settings.mods_root = root
    end

    -- Get the first folder after root path
    mod_name = file_uri:match(root .. "[\\/]([^\\/]+)[\\/]") --[[@as string?]]
    if not mod_name then
      log.warn(("Could not determine mod name for uri: %s in %s mode."):format(file_uri, mode))
      mod_name = settings.fallback_mod_name
    end
    return mod_name
  end
  ---Shouldn't be possible to here here, but just in case.
  return settings.fallback_mod_name
end

---@alias Diff.ArrayWithCount {[integer]: Diff, ["count"]: integer}
---@class Diff
---@field start integer @ The number of bytes at the beginning of the replacement
---@field finish integer @ The number of bytes at the end of the replacement
---@field text string @ What to replace

---@param uri string @ The uri of file
---@param text string @ The content of file
---@return nil|Diff[]
function OnSetText(uri, text)
  local scope = scp.getScope(uri)
  if scope:isLinkedUri(uri) then return end
  if text:sub(1, 8) == "---@meta" or text:sub(1, 4) == "--##" then return end

  local diffs = { count = 0 } ---@type Diff.ArrayWithCount

  if not settings.disable_require then require_module(uri, text, diffs) end
  if not settings.disable_global then global(uri, text, diffs, get_mod_name(scope, uri), settings) end
  if not settings.disable_remote then remote(uri, text, diffs) end
  if not settings.disable_event then on_event(uri, text, diffs) end

  diffs.count = nil
  return diffs
end
