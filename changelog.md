
### 2021-07-21
- Update for `sumneko.lua` `2.2.0` internal changes
- Improve readme grammer. I think.

### 2021-06-27
- Update readme to note to configure the `Lua.runtime.plugin` setting since that defaults to `""` instead of `".vscode/lua/plugin.lua"` since `sumneko.lua` 2.0.0

### 2021-06-18
- Add Event Handler Parameter Annotating. See readme for explanation and exact behavior, though the latter may not be the most useful
- Fix "__all_remote_interfaces" `undefiend-field` warnings for `remote.add_interface` and `remote.call` when `remote` has a specific type defined
- Hotfix commented out `remote.add_interface` and `remote.call` generating errors

### 2021-05-08
- Add ---@narrow to change the type of a variable

### 2021-03-08
- Implement remote.add_interface. See readme for potential quirks
- Add light support for ---@typelist being commented out
