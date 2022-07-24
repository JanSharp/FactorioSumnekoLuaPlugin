local ws = require("workspace")
local cfg = require('config')

---@alias fplugin.settings.available_settings 'mode'|'global'|'no_class_warning'|'disable'
---@alias fplugin.settings.modules 'event'|'require'|'global'|'remote'
---@alias fplugin.settings.modes 'folder' | 'mods'
---@class fplugin.settings
---@field mode fplugin.settings.modes
---@field mod_name? string Cached value of the mod name, not used if mode is `mods`
---@field mods_root? string Cached value of the mods root folder, not used if mode is `folder`
---@field global_as_class? boolean
---@field no_class_warning? boolean Disables the warning for undefined-doc-name
local settings = {
  mode = "folder",
  fallback_mod_name = "FallbackModName",
  ---pluginArgs can be retrieve from the config object or as the second vararg of main file.
  plugin_args = cfg.get(ws.rootUri, "Lua.runtime.pluginArgs") ---@type string[]
}

do ---@block Update Settings on init
  ---`--mode` can be either
  ---`folder` where each mod is its own workspace, or
  ---`mods` where the root mods folder is the workspace.
  local args = settings.plugin_args
  for i = 1, #args do

    local setting, option = args[i]:match("^%-%-(%w+)%s*=?%s*(%w+)") ---@type fplugin.settings.available_settings, string

    if setting == "mode" then
      if not (option == "folder" or option == "mods") then
        return log.error("wrong mode for plugin: " .. option .. " expected 'mods' or 'folder'.")
      end
      settings.mode = option
      log.info(("Plugin running in %s mode"):format(option))
    end

    if setting == "global_as_class" then
        settings.global_as_class = true
        print("Global will be defined as a class")
    end

    if setting == "no-class-warning" then
      settings.no_class_warning = true
      print("No warning on undefined global class")
    end

    if setting == "disable" then
      ---@cast option fplugin.settings.modules
      if option == "event" then
        settings.disable_event = true
      elseif option == "require" then
        settings.disable_require = true
      elseif option == "global" then
        settings.disable_global = true
      elseif option == "remote" then
        settings.disable_remote = true
      end
    end
  end
end

return settings
