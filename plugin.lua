--##
---cSpell:ignore userdata, nups, nparams

-- (this should probably be in some better location, maybe the readme? i'm not sure)
-- what do the different prefixes for gmatch results mean:
-- s = start, f = finish, p = position, no prefix = an actual string capture

---Dev Notes: confirm "path/to/lua-language-server/script/", in Lua.Workspace.Library for completions

local ws = require("workspace")
local scp = require("workspace.scope")
local cfg = require('config')

local require_module = require("factorio-plugin.require")
local global = require("factorio-plugin.global")
local remote = require("factorio-plugin.remote")
local on_event = require("factorio-plugin.on-event")

---@alias fplugin.modes 'folder' | 'mods'
---@class fplugin.settings
---@field mode fplugin.modes
---@field mod_name? string Cached value of the mod name, not used if mode is `mods`
---@field mods_root? string Cached value of the mods root folder, not used if mode is `folder`
local settings = {
  mode = "folder",
  fallback_mod_name = "FallbackModName",
  ---pluginArgs can be retrieve from the config object or as the second vararg of this chunk.
  plugin_args = cfg.get(ws.rootUri, "Lua.runtime.pluginArgs") ---@type string[]
}

do ---@block Settings
  local args = settings.plugin_args
  for i = 1, #args do
    ---`--mode` can be either
    ---`folder` where each mod is its own workspace, or
    ---`mods` where the root mods folder is the workspace.
    local setting, mode = args[i]:match("^%-%-(%w+)%s*(%w+)") ---@type string, string
    if setting == "mode" then
      if not (mode == "folder" or mode == "mods") then
        return log.error("wrong mode for plugin: " .. mode .. " expected 'mods' or 'folder'.")
      end
      settings.mode = mode
      log.info(("Plugin running in %s mode"):format(mode))
    end
  end
end
print("Factorio Plugin loaded in " .. settings.mode .. " mode")

  --[[
    In `folder` mode cache and return the mod name.\
    In `mods` mode the mod name changes depending on the file being edited so it can't be cached in `settings.mod_name`.\
    For example in the file `C:\\Factorio-Game\\MyModsFolder\\MyMod\\control.lua`
    The mod_root would be `MyModsFolder` which can be cached as `settings.mod_root` and `MyMod` would be the mod_name which can't be cached.
  ]]
---@param scope scope
---@param file_uri string
local function get_mod_name(scope, file_uri)
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

  require_module(uri, text, diffs)
  global(uri, text, diffs, get_mod_name(scope, uri))
  remote(uri, text, diffs)
  on_event(uri, text, diffs)

  diffs.count = nil
  return diffs
end
