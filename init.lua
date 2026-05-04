-- ============================================================================
-- Neovim Configuration with vim.pack (nvim 0.12+)
-- ============================================================================
-- Migrated from lazy.nvim to vim.pack
-- Reference: https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack.html
-- ============================================================================
--
-- ┌─────────────────────────────────────────────────────────────────────────────┐
-- │ File Structure                                                              │
-- └─────────────────────────────────────────────────────────────────────────────┘
--
-- This config is organized into the following structure:
--
-- ├── init.lua                    Entry point, loading helpers, plugin manager
-- ├── plugin/                     Automatically sourced during startup
-- │   ├── 10_options.lua          Built-in Neovim options, behavior
-- │   ├── 20_mini.lua             Mini.nvim configuration (all mini plugins)
-- │   ├── 30_treesitter.lua       Treesitter, UFO folding, guess-indent
-- │   ├── 40_lsp.lua              LSP, Completion, and Diagnostics (trouble)
-- │   ├── 50_edit.lua             Editing tools (formatting, multicursor, grug-far, auto-save, undotree, quicker)
-- │   ├── 60_dev.lua              Dev tools (git, runner, terminal, test, dap, kulala)
-- │   └── 99_gui.lua              GUI settings (Neovide, etc.)
-- ├── after/                      Files to override behavior added by plugins
-- │   ├── ftplugin/               Filetype-specific settings (per-buffer/window)
-- │   ├── lsp/                    Language server configurations
-- │   └── snippets/               Higher priority snippet files
-- ├── snippets/                   User-defined snippets
-- │   └── global.json             Global snippets available in all files
-- └── nvim-pack-lock.json         Plugin lockfile (auto-generated)
--
-- Key conventions:
-- - Files in plugin/ are loaded automatically by Neovim
-- - Files in after/ have higher priority and override defaults
-- - Use `:h vim.pack-examples` for plugin management
-- - Use `:h MiniMisc.safely()` for lazy loading
--
-- Navigation tips:
-- - `<leader>f` - Find files (mini.pick)
-- - `<leader>/` - Live grep (mini.pick)
-- - `<leader>E` - File explorer (mini.extra)

-- Define config table for cross-script communication
_G.Config = {}

-- ============================================================================
-- Plugin Manager Setup (vim.pack)
-- ============================================================================

-- Add mini.nvim first as it's used by many things
vim.pack.add({ 'https://github.com/nvim-mini/mini.nvim' })

-- ============================================================================
-- Loading Helpers from mini.misc
-- ============================================================================
--
-- now: execute immediately (for startup-critical)
-- later: execute after startup (for non-critical)
-- now_if_args: execute now if nvim started with file args, else later
-- on_event: execute once on specific event
-- on_filetype: execute once on specific filetype
--
-- See: https://github.com/nvim-mini/mini.misc

local misc = require('mini.misc')

Config.now = function(f)
  misc.safely('now', f)
end
Config.later = function(f)
  misc.safely('later', f)
end
Config.now_if_args = vim.fn.argc(-1) > 0 and Config.now or Config.later
Config.on_event = function(ev, f)
  local ev_name = type(ev) == 'table' and table.concat(ev, ',') or ev
  misc.safely('event:' .. ev_name, f)
end
Config.on_filetype = function(ft, f)
  local ft_name = type(ft) == 'table' and table.concat(ft, ',') or ft
  misc.safely('filetype:' .. ft_name, f)
end

Config.pick_later = function(opts, on_choose)
  vim.schedule(function()
    local chosen = require('mini.pick').start(opts)
    if chosen and on_choose then
      on_choose(chosen)
    end
  end)
end

-- ============================================================================
-- Helper for creating autocommands
-- ============================================================================

local gr = vim.api.nvim_create_augroup('custom-config', {})
Config.new_autocmd = function(event, pattern, callback, desc, opts_extra)
  local opts = { group = gr, pattern = pattern, callback = callback, desc = desc }
  if opts_extra then
    opts = vim.tbl_extend('force', opts, opts_extra)
  end
  vim.api.nvim_create_autocmd(event, opts)
end

-- ============================================================================
-- Helper for pack hooks
-- ============================================================================

Config.on_packchanged = function(plugin_name, kinds, callback, desc)
  local f = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if not (name == plugin_name and vim.tbl_contains(kinds, kind)) then
      return
    end
    if not ev.data.active then
      vim.cmd.packadd(plugin_name)
    end
    callback(ev.data)
  end
  Config.new_autocmd('PackChanged', '*', f, desc)
end
