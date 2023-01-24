
# Introduction

This is a plugin for the [sumneko.lua](https://github.com/sumneko/lua-language-server) vscode extension to help with factorio related syntax and intellisense.

# Deprecated

The version `1.1.24` of the [Factorio Modding Toolkit](https://github.com/justarandomgeek/vscode-factoriomod-debug) (previously known as Factorio Mod Debug) now includes this plugin which makes installing it and keeping it up to date easier. Further development of the plugin is also moved to that repository, this repository here will not be updated.

## Migrating

If you had this plugin installed manually and wish to migrate to the new version of the Factorio Modding Toolkit, all you have to do is delete the local clone (the folder) of the plugin and remove the manually set `Lua.runtime.plugin` setting. There's a chance that the Factorio Modding Toolkit will trigger sumneko.lua to set the `Lua.runtime.plugin` setting again, in which case you should probably keep that. This interaction isn't exactly smooth yet, so I can't guarantee it'll behave exactly as described, but if for whichever reason the plugin seems to not be taking effect (like when you do `script.on_event` and the callback's event parameter doesn't get typed correctly) I suggest to keep pressing buttons, reloading the workspace and reading Factorio Modding Toolkit workspace setup docs [here](https://github.com/justarandomgeek/vscode-factoriomod-debug/blob/current/doc/workspace.md) and [here](https://github.com/justarandomgeek/vscode-factoriomod-debug/blob/current/doc/language-lua.md) until it works.

## Documentation

With the move to the Factorio Modding Toolkit the documentation moved there as well: [Plugin Features](https://github.com/justarandomgeek/vscode-factoriomod-debug/blob/current/doc/language-lua.md#plugin-features).
