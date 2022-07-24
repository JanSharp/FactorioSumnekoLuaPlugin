---@param plugin_args string[]
return function(_, plugin_args)
  ---@class fplugin.settings
  local settings = {
    mode = "folder",
    fallback_mod_name = "FallbackModName",
    ---pluginArgs can be retrieve from the config object or as the second vararg of main file.
    plugin_args = plugin_args
  }

  local args = settings.plugin_args
  for i = 1, #args do

    ---@type fplugin.settings.available_settings, string
    local setting, option = args[i]:match("^%-%-([%-%w]+)%s?[= ]*%s?([%-%w]*)")

    if setting == "mode" then
      if not (option == "folder" or option == "mods") then
        return log.error("wrong mode for plugin: " .. option .. " expected 'mods' or 'folder'.")
      end
      settings.mode = option
      log.info(("Plugin running in %s mode"):format(option))
    end

    if setting == "global-as-class" then
      settings.global_as_class = true
      print(_, "Global will be defined as a class")
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
