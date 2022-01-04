
# Introduction

This is a plugin for the [sumneko.lua](https://github.com/sumneko/lua-language-server) vscode extension to help with factorio related syntax and intellisense.

To keep up with this project check the [changelog](changelog.md).

# Installing and updating

## How to install - clone

To use this plugin clone this repository into your `.vscode/lua` folder:

- If you don't already have git installed, download it from [here](https://git-scm.com/).
- In vscode right click on your `.vscode` folder and click `Open in Integrated Terminal`.
- In the terminal run:
```powershell
git clone --single-branch --branch master https://github.com/JanSharp/FactorioSumnekoLuaPlugin.git lua
```
This will clone the master branch of this repository into the `lua` folder from the current directory, which is the `.vscode` directory.

Since `sumneko.lua` 2.0.0 `Lua.runtime.plugin` defaults to `""` instead of `".vscode/lua/plugin.lua"`
so you'll have to configure this setting to `".vscode/lua/plugin.lua"` yourself. Best would be to do this per workspace for security.

After installing make sure to reload vscode.

## How to update

To update the plugin simply use `git pull`. The master branch should always be in a functional state.

- In vscode right click on your `.vscode/lua` folder and click `Open in Integrated Terminal`.
- In the terminal run:
```powershell
git pull
```
Or use any other method of using git you're comfortable with.

After updating make sure to reload vscode.

## But i'm different

If you happen to have a different setup and cannot put the repository in its default location, clone it to wherever you want (the folder does not have to be called `lua` anymore at that point) and then configure the `Lua.runtime.plugin` setting. The file name of the plugin entrypoint is `plugin.lua`. It can be a relative path from the root of the workspace directory. (Best would be to do this per workspace for security.)

### But i'm also very new

If you're new to command line programs and you cannot use the `Open in Integrated Terminal` in your case, simply use the `cd` "command" (i think it's called) in any command line to navigate to the directory you want to clone the repository into.

For example open a command line window or terminal of some kind (on windows i'd use `git bash` which comes with git. Just search for it in the start menu).
```
cd C:/dev/factorio/modding
git clone --single-branch --branch master https://github.com/JanSharp/FactorioSumnekoLuaPlugin.git
```
And to update:
```
cd C:/dev/factorio/modding/FactorioSumnekoLuaPlugin
git pull
```
(git bash doesn't like back slashes)
And if the workspace is at `C:/dev/factorio/modding` the `Lua.runtime.plugin` would be set to `FactorioSumnekoLuaPlugin/plugin.lua`, most likely as a workspace setting, not system wide setting.

# Help, it broke!

If the plugin is causing the language server to report syntax errors when there really aren't any and you need a temporary "solution" before reporting the issue and waiting for a fix simply put `--##` at the very very start of the file. If it is a problem that it has to be at the very start of the file please create an issue with a reason/an example for it.

# Features

## Introduction

What the plugin fundamentally does is make the lua extension (to which i'll refer to as lua language server) think files look different than they actually do. This allows for the language server to understand custom syntax, which factorio doesn't have a lot of, but it does help with a few things. 

## Cross mod require

In factorio to require files from other mods you use
```lua
require("__modname__.filename")
```
however the folder `__modname__` does not exist, which means the language server cannot find the file and cannot assist you with any kind of intellisense, mainly to know what the file returns and to navigate to definitions and find references.

The plugin makes these look like this to the language server
```lua
require("modname.filename")
```
That means if there is a folder with the name `modname` it can now find the files.

It will not work with mod folders with version numbers. I recommend not using versions on the folders anymore.

[More details](documentation.md#Cross-mod-require).

## Normalized require

The module paths passed to `require` also get normalized to follow `this.kind.of.pattern` to make sure the language server fines the files.

For example
```lua
require("folder.foo")
require("folder/bar")
require("folder/baz.lua")
```
Would look like this to the language server
```lua
require("folder.foo")
require("folder.bar")
require("folder.baz")
```

[More details](documentation.md#Normalized-require).

## Factorio global

If the language server sees multiple mods it can happen that it thinks your `global` contains keys/data it really doesn't because some other mod stores said data in `global`. For that reason the plugin tries its best to make `global` look like `__modname__global` to the language server.

[More details](documentation.md#Factorio-global).

## Event Handler Parameter Annotating

When using generated EmmyLua docs for the Factorio API from the JSON docs ([such as mentioned in this section](https://github.com/justarandomgeek/vscode-factoriomod-debug/blob/master/workspace.md#editor--extensions)) the plugin can help reduce how many type annotations you have to write manually by automatically adding type annotations for event handler parameters within `script.on_event` calls (or the other 2 variants from [flib](https://factoriolib.github.io/flib/modules/event.html) or [Stdlib](http://afforess.github.io/Factorio-Stdlib/modules/Event.Event.html)). This also works with an array of event names.

If you ever want or need this to be disabled for a specific event handler put `--##` somewhere after the parameter name of the handler but before the end of line. This may be required when annotating custom event handlers.

[More details](documentation.md#Event-Handler-Parameter-Annotating).

## Remotes

To help with intellisense for remotes, such as go to definition or knowing about which parameters a remote interface function takes and what it returns the plugin makes `remote.call` and `remote.add_interface` calls look different to the language server.

For example
```lua
remote.add_interface("foo", {
  ---Hello World!
  ---@param hello string
  ---@param world string
  ---@return number
  bar = function(hello, world)
    return 42
  end,
})

remote.call("foo", "bar", "arg 1", "arg 1")
```
Would look something similar to this to the language server
```lua
remote.__all_remote_interfaces.foo = {
  ---Hello World!
  ---@param hello string
  ---@param world string
  ---@return number
  bar = function(hello, world)
    return 42
  end,
}

remote.__all_remote_interfaces.foo.bar("arg 1", "arg 2")
```

Then when you for example hover over the string `"bar"` in the `remote.call` call you should get intellisense showing the signature of the function bar as defined above.

There is the chance that the plugin breaks parenthesis related to `add_interface` calls, if that seems to be the case please check out:\
[More details](documentation.md#Remotes).

## ---@typelist

The language server is getting better support for EmmyLua annotations, but it is really missing a way to define multiple types on the same line. For example for functions that return multiple values.

For example
```lua
---@typelist integer, string
local foo, bar = string.match("Hello world!", "()(l+)")
```
Would look something similar to this to the language server
```lua
---@type integer
local foo,
---@type string
bar = string.match("Hello world!", "()(l+)")
```

[More details](documentation.md#---typelist).

## ---@narrow

**Important:** Does not work in `sumneko.lua` `2.4.0` or later and there is currently no other known workaround. See [this issue](https://github.com/sumneko/lua-language-server/issues/704)

Another thing the annotations are currently lacking is a way to change the type of a variable, which is usually something you want in order to narrow down the type of that variable.

For example
```lua
---@param value any
local function foo(value)
  if type(value) == "string" then
    ---@narrow value string
    -- now value is a string, not any
  end
end
```
Would look something similar to this to the language server
```lua
---@param value any
local function foo(value)
  if type(value) == "string" then
    value = nil ---@type string
    -- now value is a string, not any
  end
end
```

[More details](documentation.md#---narrow).
