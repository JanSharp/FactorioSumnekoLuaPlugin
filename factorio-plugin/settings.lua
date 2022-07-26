local fs = require('bee.filesystem') ---@type fs
local ws = require('workspace')

---@param scp scope
---@param plugin_args string[]
---@return fplugin.settings
return function(scp, plugin_args)
  local scp_name = scp.uri:match("[^/\\]+$")
  ---@class fplugin.settings
  local settings = {
    fallback_mod_name = "FallbackModName",
    ---pluginArgs can be retrieved:
    -- - from the config object
    -- - as the third vararg of main file
    -- - from scp:get('Lua.runtime.pluginArgs')
    plugin_args = plugin_args
  }

  local args = settings.plugin_args
  for i = 1, #args do

    ---@type fplugin.settings.available_settings, string
    local setting, option = args[i]:match("^%-%-([%-%w]+)%s?[= ]*%s?([%-%w]*)")

    if setting == "mode" then
      if option == "folder" then
        settings.mode = "folder"
      elseif option == "mods" then
        settings.mode = "mods"
      else
        log.error("wrong mode for plugin: " .. option .. " expected 'mods' or 'folder'.")
        return ---@diagnostic disable-line: missing-return-value
      end
      print(scp_name, ("running in %s mode"):format(option))
    end

    if setting == "global-as-class" then
      settings.global_as_class = true
      print(scp_name, ("Global will be defined as a class"))
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

  ---Attempt to auto determine folder mode if settings.mode is not explicitly set.
  if not settings.mode then
    local info_json = fs.exists(fs.path(ws.getAbsolutePath(scp.uri, "info.json")))
    if info_json then
      settings.mode = "folder"
      print(scp_name, ("running in `%s` mode (auto-detected)"):format("folder"))
    else
      settings.mode = "mods"
      print(scp_name, ("running in `%s` mode (auto-detected)"):format("mods"))
    end
  end
  return settings
end

---@alias fplugin.settings.available_settings 'mode'|'global-as-class'|'disable'
---@alias fplugin.settings.modules 'event'|'require'|'global'|'remote'
---@alias fplugin.settings.modes 'folder' | 'mods'

---@class fplugin.settings
---@field mode fplugin.settings.modes
---@field mod_name? string Cached value of the mod name, not used if mode is `mods`
---@field mods_root? string Cached value of the mods root folder, not used if mode is `folder`
---@field global_as_class? boolean
---@field no_class_warning? boolean Disables the warning for undefined-doc-name
