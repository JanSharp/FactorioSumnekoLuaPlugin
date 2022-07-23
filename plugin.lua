--##
---cSpell:ignore userdata, nups, nparams

-- (this should probably be in some better location, maybe the readme? i'm not sure)
-- what do the different prefixes for gmatch results mean:
-- s = start, f = finish, p = position, no prefix = an actual string capture

---Dev Notes: confirm "path/to/lua-language-server/script/", in Lua.Workspace.Library for completions

local scp = require("workspace.scope")

local require_module = require("factorio-plugin.require")
local global = require("factorio-plugin.global")
local remote = require("factorio-plugin.remote")
local on_event = require("factorio-plugin.on-event")

---@alias fplugin.modes 'folder' | 'mods'
---@class fplugin.settings
---@field mode fplugin.modes
---@field mod_name? string
---@field mods_root? string
local settings = {
  mode = "folder",
  fallback_mod_name = "FallbackModName"
}

do ---@block Settings
  local args = select(2, ...) ---@type string[]
  for i = 1, #args do
    --mode: Switch between folder mode where each mod is its own workspace, and mods mode where the root mods folder is the workspace.
    local setting, mode = args[i]:match("^%-%-(%w+)%s*(%w+)") ---@type string, string
    if setting == "mode" then
      if not (mode == "folder" or mode == "mods") then
        return log.error("wrong mode for plugin: ".. mode .. " expected 'mods' or 'folder'.")
      end
      settings.mode = mode
      log.info(("Plugin running in %s mode"):format(mode))
    end
  end
end
print("Factorio Plugin loaded in ".. settings.mode .." mode")

local function get_mod_name(uri)
  if settings.mod_name then return settings.mod_name end

  local mod_name ---@type string?

  ---Cache the mod name in folder mode
  if settings.mode == "folder" then
    mod_name = scp.getScope(uri).uri:match("[^/\\]+$")  --[[@as string?]]
    settings.mod_name = mod_name
    return mod_name
  end

  ---Mods mode the mod name changes depending on the file being edited
  if settings.mode == "mods" then
    -- The root folder path
    local root = settings.mods_root
    if not root then
      local scope = scp.getScope(uri)
      -- get the end folder of root path
      root = scope.uri:match("[^/\\]+$")
      settings.mods_root = root
    end

    -- get the first folder after root path
    mod_name = uri:match(root .."[\\/]([^\\/]+)[\\/]") --[[@as string?]]
    if not mod_name then
      log.warn(("Could not determine mod name for uri: %s in %s mode."):format(uri, settings.mode))
      mod_name = settings.fallback_mod_name
    end
    print("in mod name ", mod_name)
    return mod_name
  end

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
  if scp.getScope(uri):isLinkedUri(uri) then return end

  if text:sub(1, 8) == "---@meta" or text:sub(1, 4) == "--##" then return end

  local diffs = {count = 0} ---@type Diff.ArrayWithCount

  require_module.replace(uri, text, diffs)
  global.replace(uri, text, diffs, get_mod_name(uri))
  remote.replace(uri, text, diffs)
  on_event.replace(uri, text, diffs)

  diffs.count = nil
  return diffs
end
