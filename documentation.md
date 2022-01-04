
# Cross mod require

Since the plugin essentially just removes the `__` from the path, you still have to make sure that the language server can actually find that path. When using library paths (`Lua.workspace.library` setting) make sure the file/path you are requiring is fully _inside_ the paths you defined as a library.

I'm not going to add support for version numbers on the folder names because it significantly increases complexity of this feature for something hardly anybody is going to use, plus they probably shouldn't be using it anymore either. It could even be ambiguous between multiple versions. Zip files are just not supported, period.

# Normalized require

The language server does understand module names using either `.` or `/` and it can probably be configured to understand `folder/baz.lua` as well if you adjust the `Lua.runtime.path` setting to something like `["?.lua", "?"]`, however every time I try to figure out how exactly it works it seems a bit funky, sometimes working and sometimes not, or just not behaving as expected.

For that reason the plugin just normalizes all of them to `foo.bar` because that always worked so far, also with default settings. Plus in the past `/` was not supported by the language server itself.

# Factorio global

- only touches those where `global` is followed by `.` (a dot), `[` (open square bracket) or `=` (equals).
- doesn't touch `.global` (`global` being the key used to index into something)
- figures out what `modname` to use by looking for `mods/<modname>/` in the fully qualified URI of the current file.
- if it found a modname it also looks for `scenarios/<scenarioname>/` and actually makes `global` look like `__modname__scenarioname__global`
- checks for both `/` and `\` just in case the URIs (provided by the language server) use `\` on windows

# Event Handler Parameter Annotating

The specific behavior is hard to put in words but I shall try:\
For all calls to `on_event`, `event.register` or `Event.register` it gets all event names a handler is being registered for which is either just the single one provided or the list of event "names". It then gets the parameter name used for the event data in the handler function provided (it only works when the function is defined in place, not for references to a previously defined function) and it adds an `@param` annotation for this parameter. For every event name previously found it tries to get the type name to use for this annotation by getting the last part in the indexing chain/expression and combines then with a `|` between each of them to tell the language server that it could be any of those given types, but it will only use the types that start with `on_` or `script_`. If it finds a string literal it also adds `CustomInputEvent` to this type list.

`flib` and `stdlib` add another way of registering handlers, such as `event.on_tick(function(e) end)`. These are much easier to explain:\
It searches for `event.` or `Event.` followed by an identifier which gets called with a function being passed in as the first argument. Then it adds the annotaion just as before by getting the parameter name used for the event data for the handler and adds an `@param` annotation for this parameter using the found function name (the identifier after `event.` or `Event.`) as the type name for the parameter without any further filtering on the name.

It doesn't do anything if it finds `--` somewhere in the line before whichever call it is processing.

It disables `undefined-doc-name` diagnostics on the `@param` annotation line because it can find false positives or one might not be using the generated EmmyLua docs.

<!--

For example
```lua
script.on_event(defines.events.on_tick, function(event)
  print("Hello World!")
end)

event.register(defines.events.on_built_entity, function(e) end)

Event.on_built_entity(function(e) end)
```
Would look something similar to this to the language server
```lua
script.on_event(defines.events.on_tick,
---@diagnostic disable-next-line:undefined-doc-name
---@param event on_tick
function(event)
end)

event.register(defines.events.on_built_entity,
---@diagnostic disable-next-line:undefined-doc-name
---@param e on_built_entity
function(e) end)

Event.on_built_entity(
---@diagnostic disable-next-line:undefined-doc-name
---@param e on_built_entity
function(e) end)
```

For example
```lua
script.on_event({
  defines.events.script_raised_built,
  defines.events.on_built_entity,
}, function(event)
end)

event.register({
  defines.events.script_raised_built,
  defines.events.on_built_entity,
}, function(e) end)
```
Would look something similar to this to the language server
```lua
script.on_event({
  defines.events.script_raised_built,
  defines.events.on_built_entity,
},
---@diagnostic disable-next-line:undefined-doc-name
---@param event script_raised_built|on_built_entity
function(event)
end)

event.register({
  defines.events.script_raised_built,
  defines.events.on_built_entity,
},
---@diagnostic disable-next-line:undefined-doc-name
---@param e script_raised_built|on_built_entity
function(e) end)
```

For example
```lua
script.on_event("on_tick", function(event)
end)

script.on_event(on_custom_event, function(event)
end)

---@param event my_on_custom_event_type
script.on_event(on_custom_event, function(event) --##
end)
```
Would look something similar to this to the language server
```lua
---@diagnostic disable-next-line:undefined-doc-name
---@param event CustomInputEvent
script.on_event("on_tick", function(event)
end)

script.on_event(on_custom_event,
---@diagnostic disable-next-line:undefined-doc-name
---@param event on_custom_event
function(event)
end)

---@param event my_on_custom_event_type
script.on_event(on_custom_event, function(event) --##
end)
```

-->

# Remotes

It also disables `undefined-field` diagnostics specifically for `__all_remote_interfaces`.

It does nothing if it finds `--` before `remote` on the same line.

### More about remote.add_interface

**Important:** If you are having trouble with this (described below), I suggest using this format of adding the remote interface instead, since it will never break with the plugin:
```lua
-- declare local first
local foo = {
  bar = function()
    -- stupid and weird amounts of parenthesis
    return "())(((()())(())()))())"
  end,
}
-- then just use the local in `add_interface`
remote.add_interface("foo", foo)
```

If you payed close attention to [the example in the readme](README.md#Remotes) you may notice that the `remote.add_interface` replacement has to remove the closing `)` (parenthesis) of the call. In order to find this parenthesis it's using `%b()` in a Lua pattern, which means it can fail to find the right parenthesis if there are unbalanced or escaped parenthesis inside strings or comments. You can either manually add parenthesis inside comments to balance them out again, or preferably you can add `--##` somewhere within or after the `remote.add_interface` call, but the earlier the better, because the plugin will only search for it until the end of the line where it found its closing parenthesis.

`--##` tells the plugin not to do anything for this `add_interface` call.

Here are some examples
```lua
remote.add_interface("foo", {
  bar = function()
    return ")"
  end,
})

remote.add_interface("foo", {
  bar = function() -- ( for plugin
    return ")"
  end,
})

remote.add_interface("foo", { --## plugin, don't even try
  bar = function()
    return "())(((()())(())()))())"
  end,
})

local foo = {
  bar = function()
    return "())(((()())(())()))())"
  end,
}
remote.add_interface("foo", foo)
```
Would look something similar to this to the language server (notice the strings)
```lua
remote.__all_remote_interfaces.foo = {
  bar = function()
    return ""
  end,
})

remote.__all_remote_interfaces.foo = {
  bar = function() -- ( for plugin
    return ")"
  end,
}

remote.add_interface("foo", { --## plugin, don't even try
  bar = function()
    return "())(((()())(())()))())"
  end,
})

local foo = {
  bar = function()
    return "())(((()())(())()))())"
  end,
}
remote.__all_remote_interfaces.foo = foo
```

# ---@typelist

It looks for `---@typelist` (with spaces allowed between `---` and `@typelist`) being on one line and it only affects the next line. And it uses `,` (commas) as separators. (commas inside `< >` or `( )` are ignored on the `---@typelist` line.)

It then splits up the next line based on the commas and adds a `---@type` annotation for each line.

# ---@narrow

It specifically looks for `---@narrow` (with spaces allowed between `---` and `@narrow`) followed by space and an identifier, then does the replacement so that the type is actually used in place, exactly how/where you wrote it.

Unfortunately since it is using `nil` as a placeholder assignment the language server will think the variable can be `nil` even though it might never be. An expression the language server resolves to `any` would be better, but i don't know of one right now.
