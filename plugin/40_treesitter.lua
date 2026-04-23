-- ============================================================================
-- Treesitter Configuration (plugin/40_treesitter.lua)
-- ============================================================================

local add = vim.pack.add
local now_if_args = Config.now_if_args

now_if_args(function()
  -- Define hook to update tree-sitter parsers after plugin is updated
  Config.on_packchanged('nvim-treesitter', { 'update' }, function()
    vim.cmd('TSUpdate')
  end, ':TSUpdate')

  add({
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
  })

  -- Languages to install
  local languages = {
    'c',
    'cpp',
    'rust',
    'python',
    'lua',
    'go',
    'json',
    'yaml',
    'javascript',
    'typescript',
    'markdown',
    'proto',
    'zig',
  }

  local installed_parsers = require('nvim-treesitter.config').get_installed('parsers')
  local isnt_installed = function(lang)
    return not vim.tbl_contains(installed_parsers, lang)
  end

  local to_install = vim.tbl_filter(isnt_installed, languages)
  if #to_install > 0 then
    require('nvim-treesitter').install(to_install)
  end

  -- Enable tree-sitter after opening a file for target languages
  local filetypes = vim
    .iter(languages)
    :map(function(l)
      return vim.treesitter.language.get_filetypes(l)
    end)
    :flatten()
    :totable()

  Config.new_autocmd('FileType', filetypes, function(ev)
    pcall(vim.treesitter.start, ev.buf)
  end, 'Start tree-sitter')

  -- Disable for large files
  Config.new_autocmd('BufReadPost', '*', function(args)
    local max_filesize = 100 * 1024 -- 100 KB
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
    if ok and stats and stats.size > max_filesize then
      vim.treesitter.stop(args.buf)
    end
  end, 'Disable treesitter for large files')

  -- Configure nvim-treesitter-textobjects
  require('nvim-treesitter-textobjects').setup({
    select = { lookahead = true },
    move = { set_jumps = true },
  })

  -- Textobject keymaps
  Config.later(function()
    local select = require('nvim-treesitter-textobjects.select')
    local move = require('nvim-treesitter-textobjects.move')

    for _, spec in ipairs({
      { 'af', '@function.outer' },
      { 'if', '@function.inner' },
      { 'ac', '@class.outer' },
      { 'ic', '@class.inner' },
      { 'ab', '@block.outer' },
      { 'ib', '@block.inner' },
    }) do
      vim.keymap.set({ 'x', 'o' }, spec[1], function()
        select.select_textobject(spec[2], 'textobjects')
      end)
    end

    for _, spec in ipairs({
      { ']m', 'goto_next_start', '@function.outer' },
      { ']][', 'goto_next_start', '@class.outer' },
      { ']M', 'goto_next_end', '@function.outer' },
      { '][', 'goto_next_end', '@class.outer' },
      { '[m', 'goto_previous_start', '@function.outer' },
      { '[[', 'goto_previous_start', '@class.outer' },
      { '[M', 'goto_previous_end', '@function.outer' },
      { '[]', 'goto_previous_end', '@class.outer' },
    }) do
      vim.keymap.set('n', spec[1], function()
        move[spec[2]](spec[3], 'textobjects')
      end)
    end
  end)
end)

-- ============================================================================
-- UFO (folding) - Load on BufReadPost/BufNewFile
-- ============================================================================

Config.new_autocmd({ 'BufReadPost', 'BufNewFile' }, '*', function()
  if package.loaded['ufo'] then
    return
  end

  add({
    'https://github.com/kevinhwang91/nvim-ufo',
    'https://github.com/kevinhwang91/promise-async',
  })

  vim.opt.foldenable = true
  vim.opt.foldcolumn = '0'
  vim.opt.foldlevel = 99
  vim.opt.foldlevelstart = 99

  require('ufo').setup({
    provider_selector = function()
      return { 'treesitter', 'indent' }
    end,
  })

  vim.keymap.set('n', 'zR', require('ufo').openAllFolds, { desc = 'Open all folds' })
  vim.keymap.set('n', 'zM', require('ufo').closeAllFolds, { desc = 'Close all folds' })
  vim.keymap.set('n', 'zr', require('ufo').openFoldsExceptKinds, { desc = 'Open folds except kinds' })
  vim.keymap.set('n', 'zm', require('ufo').closeFoldsWith, { desc = 'Close folds with' })
  vim.keymap.set('n', 'zp', require('ufo').peekFoldedLinesUnderCursor, { desc = 'Peek folded lines' })
end, 'Setup UFO folding', { once = true })

-- ============================================================================
-- Guess-indent - Load on BufReadPre/BufNewFile
-- ============================================================================

Config.new_autocmd({ 'BufReadPre', 'BufNewFile' }, '*', function()
  if package.loaded['guess-indent'] then
    return
  end

  add({ 'https://github.com/NMAC427/guess-indent.nvim' })
  require('guess-indent').setup({
    auto_cmd = true,
    override_editorconfig = false,
    filetype_exclude = { 'netrw', 'tutor' },
    buftype_exclude = { 'help', 'nofile', 'terminal', 'prompt' },
  })
end, 'Setup guess-indent', { once = true })
