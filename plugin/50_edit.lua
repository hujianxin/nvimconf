-- ============================================================================
-- Edit Configuration (plugin/50_edit.lua)
-- ============================================================================
-- Formatting, multi-cursor, search/replace, auto-save, and undo tree.

local add = vim.pack.add
local later = Config.later

-- ============================================================================
-- Formatting
-- ============================================================================

local function fmt()
  if not package.loaded['conform'] then
    add({ 'https://github.com/stevearc/conform.nvim' })
    require('conform').setup({
      default_format_opts = { lsp_format = 'fallback' },
      formatters_by_ft = {
        cpp = { 'clang-format' },
        c = { 'clang-format' },
        proto = { 'clang-format' },
        lua = { 'stylua' },
        go = { 'goimports', 'gofmt' },
        rust = { 'rustfmt', lsp_format = 'fallback' },
        python = function(bufnr)
          if require('conform').get_formatter_info('ruff_format', bufnr).available then
            return { 'ruff_format' }
          end
          return { 'isort', 'black' }
        end,
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        bzl = { 'buildifier' },
        zig = { 'zigfmt' },
        cmake = { 'gersemi' },
      },
    })
  end
  require('conform').format({ async = true, lsp_format = 'fallback' })
end

vim.keymap.set('n', '=', fmt, { desc = 'Format code' })
vim.api.nvim_create_user_command('Format', fmt, { desc = 'Format code' })

-- ============================================================================
-- Undo tree (built-in in Neovim 0.12+)
-- ============================================================================

Config.later(function()
  vim.cmd.packadd('nvim.undotree')
  vim.keymap.set('n', '<leader>u', require('undotree').open, { desc = 'Open undotree' })
end)

-- ============================================================================
-- Auto-save
-- ============================================================================

Config.new_autocmd({ 'InsertLeave', 'TextChanged' }, '*', function()
  add({ 'https://github.com/okuuva/auto-save.nvim' })
  require('auto-save').setup()
end, 'Setup auto-save', { once = true })

-- ============================================================================
-- Multicursor
-- ============================================================================

later(function()
  add({ 'https://github.com/jake-stewart/multicursor.nvim' })
  local mc = require('multicursor-nvim')
  mc.setup()

  for _, spec in ipairs({
    {
      { 'n', 'x' },
      '<C-up>',
      function()
        mc.lineAddCursor(-1)
      end,
    },
    {
      { 'n', 'x' },
      '<C-down>',
      function()
        mc.lineAddCursor(1)
      end,
    },
    {
      { 'n', 'x' },
      '<C-n>',
      function()
        mc.matchAddCursor(1)
      end,
    },
    {
      { 'n', 'x' },
      '<C-s>',
      function()
        mc.matchSkipCursor(1)
      end,
    },
    { 'n', '<c-leftmouse>', mc.handleMouse },
    { 'n', '<c-leftdrag>', mc.handleMouseDrag },
    { 'n', '<c-leftrelease>', mc.handleMouseRelease },
    { { 'n', 'x' }, '<c-q>', mc.toggleCursor },
  }) do
    vim.keymap.set(spec[1], spec[2], spec[3])
  end

  mc.addKeymapLayer(function(layerSet)
    for _, spec in ipairs({
      { { 'n', 'x' }, '<left>', mc.prevCursor },
      { { 'n', 'x' }, '<right>', mc.nextCursor },
      { { 'n', 'x' }, '<M-x>', mc.deleteCursor },
    }) do
      layerSet(spec[1], spec[2], spec[3])
    end
    layerSet('n', '<esc>', function()
      if not mc.cursorsEnabled() then
        mc.enableCursors()
      else
        mc.clearCursors()
      end
    end)
  end)

  for _, spec in ipairs({
    { 'MultiCursorCursor', { reverse = true } },
    { 'MultiCursorVisual', { link = 'Visual' } },
    { 'MultiCursorSign', { link = 'SignColumn' } },
    { 'MultiCursorMatchPreview', { link = 'Search' } },
    { 'MultiCursorDisabledCursor', { reverse = true } },
    { 'MultiCursorDisabledVisual', { link = 'Visual' } },
    { 'MultiCursorDisabledSign', { link = 'SignColumn' } },
  }) do
    vim.api.nvim_set_hl(0, spec[1], spec[2])
  end
end)

-- ============================================================================
-- Grug-far - Search and replace
-- ============================================================================

local function grugfar(fn, ...)
  if not package.loaded['grug-far'] then
    add({ 'https://github.com/MagicDuck/grug-far.nvim' })
    require('grug-far').setup({ windowCreationCommand = 'vsplit' })
  end
  require('grug-far')[fn](...)
end

vim.keymap.set('n', '<M-S-s>', function()
  grugfar('open')
end, { desc = 'Replace in files' })
vim.keymap.set('n', '<M-S-w>', function()
  grugfar('open', { prefills = { search = vim.fn.expand('<cword>') } })
end, { desc = 'Replace current word' })
vim.keymap.set('v', '<M-S-w>', function()
  grugfar('with_visual_selection')
end, { desc = 'Replace selection' })
vim.keymap.set('n', '<M-S-f>', function()
  grugfar('open', { prefills = { paths = vim.fn.expand('%') } })
end, { desc = 'Replace in current file' })

-- ============================================================================
-- Flash.nvim - Fast navigation
-- ============================================================================

later(function()
  add({ 'https://github.com/folke/flash.nvim' })

  require('flash').setup({
    labels = 'abcdefghijklmnopqrstuvwxyz',
    search = { mode = 'fuzzy' },
    highlight = {
      backdrop = true,
      matches = true,
      priority = 5000,
      groups = {
        match = 'FlashMatch',
        current = 'FlashCurrent',
        backdrop = 'FlashBackdrop',
        label = 'FlashLabel',
      },
    },
    jump = {
      autojump = false,
      inclusive = true,
      post_jump = function()
        vim.cmd('normal! zz')
      end,
    },
    modes = {
      char = { enabled = false, jump_labels = true },
      search = { enabled = false },
    },
  })

  for _, spec in ipairs({
    {
      { 'n', 'x', 'o' },
      's',
      function()
        require('flash').jump()
      end,
      'Flash',
    },
    {
      { 'n', 'x', 'o' },
      'S',
      function()
        require('flash').treesitter()
      end,
      'Flash Treesitter',
    },
    {
      { 'o' },
      'r',
      function()
        require('flash').remote()
      end,
      'Remote Flash',
    },
    {
      { 'o', 'x' },
      'R',
      function()
        require('flash').treesitter_search()
      end,
      'Treesitter Search',
    },
    {
      { 'c' },
      '<c-s>',
      function()
        require('flash').toggle()
      end,
      'Toggle Flash Search',
    },
  }) do
    vim.keymap.set(spec[1], spec[2], spec[3], { desc = spec[4] })
  end
end)

-- ============================================================================
-- Quicker.nvim - Enhanced quickfix list
-- ============================================================================

later(function()
  add({ 'https://github.com/stevearc/quicker.nvim' })
  require('quicker').setup({
    constrain_cursor = false,
    keep_cursor = true,
    bbox = { top = 2, bottom = 2, left = 12, right = 12 },
    trim_lines = true,
    header_duration = 150,
  })
end)
