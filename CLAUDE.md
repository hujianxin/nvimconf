# Package Removal Guide

To remove a package, delete both:

1. Directory: `~/.local/share/nvim/site/pack/core/opt/<plugin-name>/`
2. Lockfile entry: Remove the `<plugin-name>` block from `nvim-pack-lock.json`

Example for removing `LuaSnip`:

```bash
rm -rf ~/.local/share/nvim/site/pack/core/opt/LuaSnip
# Then delete the "LuaSnip" entry from nvim-pack-lock.json
```

# Custom Snippets

Place VSCode-format snippets in `snippets/` with a `package.json` descriptor. See `snippets/package.json` for the global snippets example.

# Loading Helpers

Use these helpers from `_G.Config` to load plugins with proper lazy loading:

```lua
Config.now(function() end)           -- Load immediately
Config.later(function() end)         -- Load after startup
Config.now_if_args(function() end)   -- Load now if file args, else later
Config.on_event("InsertEnter", function() end)  -- Load on event
Config.on_filetype("python", function() end)    -- Load on filetype
Config.new_autocmd("BufWritePre", "*", callback, "description")  -- Create autocmd
Config.on_packchanged("plugin", {"install", "update"}, callback, "desc")  -- Pack hook
Config.pick_later(opts, callback)  -- Start mini.pick after current picker closes
```

# mini.pick Custom Pickers

When using `MiniPick.start()` for commands that only need a selected value, disable the default choose action:

```lua
MiniPick.start({
  source = {
    items = items,
    choose = function() end,
  },
})
```

Prefer table items with a `text` field for display plus explicit data fields for behavior:

```lua
{ text = 'branch: main', rev = 'main' }
```

Reason: `mini.pick` default `choose` may treat string items as files, buffers, or URI-like paths and open them before the caller handles the returned value. This can leave stray buffers such as `branch: main`.

If a command using `MiniPick.start()` can be triggered from inside another `mini.pick` picker, start the new picker inside `vim.schedule()`:

```lua
vim.schedule(function()
  local chosen = MiniPick.start({ source = source })
  if chosen then
    -- Handle selected item here.
  end
end)
```

Reason: `mini.pick` is not designed for nested picker startup while the outer picker's choose flow is still unwinding. Scheduling lets the outer picker fully close before the new picker starts. For repeated use, prefer the shared helper:

```lua
Config.pick_later({ source = source }, function(chosen)
  -- Handle selected item here.
end)
```
