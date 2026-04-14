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
```
