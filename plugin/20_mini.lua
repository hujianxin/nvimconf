-- ============================================================================
-- Mini.nvim Configuration (plugin/30_mini.lua)
-- ============================================================================
-- All mini plugins organized with MiniMax staged loading strategy

local add = vim.pack.add
local now, now_if_args, later = Config.now, Config.now_if_args, Config.later

-- ============================================================================
-- Step One (now) - Immediately loaded for first screen rendering
-- ============================================================================

-- mini.basics - Common configuration presets
now(function()
  require('mini.basics').setup({
    options = {
      basic = false,
      extra_ui = false,
      win_borders = 'single',
    },
    mappings = {
      basic = true,
      option_toggle_prefix = [[\]],
      windows = true,
      move_with_alt = false,
    },
    autocommands = {
      basic = true,
      relnum_in_visual_mode = false,
    },
    silent = true,
  })
  -- mini.basics overrides nvim 0.12's default LSP mappings
  vim.keymap.set('n', 'gO', vim.lsp.buf.document_symbol, { desc = 'vim.lsp.buf.document_symbol()' })
  vim.keymap.set('i', '<C-s>', vim.lsp.buf.signature_help, { desc = 'vim.lsp.buf.signature_help()' })
end)

-- Set colorscheme from mini.nvim
now(function()
  vim.cmd.colorscheme('miniwinter')
end)

-- mini.icons - Icon provider
now(function()
  require('mini.icons').setup({
    style = 'glyph',
  })
  MiniIcons = require('mini.icons')
  -- Mock nvim-web-devicons for compatibility
  package.preload['nvim-web-devicons'] = function()
    require('mini.icons').mock_nvim_web_devicons()
    return package.loaded['nvim-web-devicons']
  end
  -- Add LSP kind icons for mini.completion
  later(MiniIcons.tweak_lsp_kind)
end)

-- mini.notify - Notification manager
now(function()
  require('mini.notify').setup({
    window = {
      config = { border = 'rounded' },
      winblend = 0,
    },
  })
  vim.notify = MiniNotify.make_notify()
  vim.keymap.set('n', '<leader>Tn', '<cmd>lua MiniNotify.show_history()<cr>', { desc = 'Show notification history' })
  vim.keymap.set('n', '<leader>Td', '<cmd>lua MiniNotify.clear()<cr>', { desc = 'Clear notifications' })
end)

-- mini.sessions - Session management
now(function()
  require('mini.sessions').setup({
    directory = vim.fn.stdpath('data') .. '/sessions',
    force = { write = true },
    hooks = {
      post = {
        read = function()
          vim.notify('Session loaded', vim.log.levels.INFO)
        end,
        write = function()
          vim.notify('Session saved', vim.log.levels.INFO)
        end,
      },
    },
    verbose = { write = true, delete = true },
  })

  vim.keymap.set('n', '<leader>Ss', "<cmd>lua MiniSessions.select('read')<cr>", { desc = 'Select and load session' })
  vim.keymap.set(
    'n',
    '<leader>Sd',
    "<cmd>lua MiniSessions.select('delete')<cr>",
    { desc = 'Select and delete session' }
  )
  vim.keymap.set('n', '<leader>Sw', '<cmd>lua MiniSessions.write()<cr>', { desc = 'Write current session' })
  vim.keymap.set('n', '<leader>Sr', '<cmd>lua MiniSessions.read()<cr>', { desc = 'Read last session' })

  Config.new_autocmd('VimLeavePre', '*', function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == '' and vim.api.nvim_buf_get_name(buf) ~= '' then
        MiniSessions.write('auto', { force = true })
        return
      end
    end
  end, 'Auto-save session before exit')
end)

-- mini.statusline - Statusline
now(function()
  local MiniStatusline = require('mini.statusline')

  -- Patch section_mode to return 3-letter uppercase mode
  local orig_section_mode = MiniStatusline.section_mode
  MiniStatusline.section_mode = function(args)
    local mode, mode_hl = orig_section_mode(args)
    return mode:sub(1, 3):upper(), mode_hl
  end

  MiniStatusline.setup({
    content = { active = nil, inactive = nil },
    use_icons = false,
    set_vim_settings = true,
  })
end)

-- mini.tabline - Tabline showing buffers
now(function()
  require('mini.tabline').setup({
    -- Whether to show file icons (requires 'mini.icons')
    show_icons = true,
    -- Function which formats the tab label
    -- By default surrounds with space and possibly prepends with icon
    format = nil,
    -- Where to show tabpage section in case of multiple vim tabpages.
    -- One of 'left', 'right', 'none'.
    tabpage_section = 'left',
  })
end)

-- ============================================================================
-- Step One or Two (now_if_args) - Load immediately if file args, otherwise delay
-- ============================================================================

-- mini.files - File explorer
now_if_args(function()
  local mini_files = require('mini.files')
  mini_files.setup({
    options = {
      permanent_delete = true,
      use_as_default_explorer = true,
    },
    content = {
      filter = nil,
      prefix = nil,
    },
  })
  vim.keymap.set('n', '<C-y>', function()
    mini_files.open(vim.api.nvim_buf_get_name(0))
  end, { desc = 'Open mini.files' })
  Config.new_autocmd('User', 'MiniFilesBufferCreate', function(args)
    local buf_id = args.data.buf_id
    vim.keymap.set('n', '<C-y>', function()
      mini_files.close()
    end, { buffer = buf_id, desc = 'Close mini.files' })
    vim.keymap.set('n', '<Esc>', function()
      mini_files.close()
    end, { buffer = buf_id, desc = 'Close mini.files' })
    -- Split keymaps
    local map_split = function(buf, lhs, cmd, desc)
      vim.keymap.set('n', lhs, function()
        local win
        vim.api.nvim_win_call(vim.api.nvim_get_current_win(), function()
          vim.cmd(cmd)
          win = vim.api.nvim_get_current_win()
        end)
        mini_files.set_target_window(win)
        mini_files.go_in({ close_on_file = true })
      end, { buffer = buf, desc = desc })
    end
    map_split(buf_id, '<C-x>', 'split', 'Split open')
    map_split(buf_id, '<C-v>', 'vsplit', 'Vertical split open')
    -- Tab keymap
    vim.keymap.set('n', '<C-t>', function()
      local new_target_window
      vim.api.nvim_win_call(vim.api.nvim_get_current_win(), function()
        vim.cmd('tabnew')
        new_target_window = vim.api.nvim_get_current_win()
      end)
      mini_files.set_target_window(new_target_window)
      mini_files.go_in({ close_on_file = true })
    end, { buffer = buf_id, desc = 'Open in new tab' })
    vim.keymap.set('n', '<CR>', function()
      mini_files.go_in({ close_on_file = true })
    end, { buffer = buf_id, desc = 'Open file or enter directory' })
    vim.keymap.set('n', 'g.', mini_files.synchronize, { buffer = buf_id, desc = 'Synchronize' })
    vim.keymap.set('n', 'g?', mini_files.show_help, { buffer = buf_id, desc = 'Show help' })
  end, 'Mini.files buffer keymaps')
end)

-- mini.misc - Miscellaneous useful functions
now_if_args(function()
  -- Makes `:h MiniMisc.put()` and `:h MiniMisc.put_text()` public
  require('mini.misc').setup()

  -- Change current working directory based on the current file path. It
  -- searches up the file tree until the first root marker ('.git' or 'Makefile')
  -- and sets their parent directory as a current directory.
  -- This is helpful when simultaneously dealing with files from several projects.
  MiniMisc.setup_auto_root()

  -- Restore latest cursor position on file open
  MiniMisc.setup_restore_cursor()

  -- Synchronize terminal emulator background with Neovim's background to remove
  -- possibly different color padding around Neovim instance
  MiniMisc.setup_termbg_sync()

  -- Zoom into current window (close others in tab), restore on second press
  vim.keymap.set('n', '<C-w>O', MiniMisc.zoom, { desc = 'Zoom window' })
end)

-- mini.completion - Completion and signature help
now_if_args(function()
  local process_items_opts = { kind_priority = { Text = -1, Snippet = 99 } }
  local process_items = function(items, base)
    return MiniCompletion.default_process_items(items, base, process_items_opts)
  end
  require('mini.completion').setup({
    lsp_completion = {
      source_func = 'omnifunc',
      auto_setup = false,
      process_items = process_items,
    },
  })

  -- Set 'omnifunc' for LSP completion only when needed
  local on_attach = function(ev)
    vim.bo[ev.buf].omnifunc = 'v:lua.MiniCompletion.completefunc_lsp'
  end
  Config.new_autocmd('LspAttach', nil, on_attach, "Set 'omnifunc'")
end)

-- ============================================================================
-- Step Two (later) - Delayed loaded after first screen
-- ============================================================================

-- mini.extra - Extra functionality for mini.nvim
later(function()
  require('mini.extra').setup()
  local MiniExtra = require('mini.extra')

  -- Keymaps for mini.pick + mini.extra
  for _, spec in ipairs({
    {
      '<leader>f',
      function()
        MiniPick.builtin.files()
      end,
      'Find files',
    },
    {
      '<leader>/',
      function()
        MiniPick.builtin.grep_live()
      end,
      'Live grep',
    },
    {
      '<C-e>',
      function()
        MiniPick.builtin.buffers()
      end,
      'Find buffers',
    },
    {
      '<leader>bb',
      function()
        MiniPick.builtin.buffers()
      end,
      'Find buffers',
    },

    {
      '<leader>o',
      function()
        MiniExtra.pickers.lsp({ scope = 'document_symbol' })
      end,
      'Document symbols',
    },
    {
      '<leader>s',
      function()
        MiniExtra.pickers.lsp({ scope = 'workspace_symbol_live' })
      end,
      'Workspace symbols',
    },
    {
      '<leader>d',
      function()
        MiniExtra.pickers.diagnostic()
      end,
      'Diagnostics',
    },
    {
      '<leader><space>',
      function()
        MiniExtra.pickers.history({ scope = ':' })
      end,
      'Command history',
    },
    {
      '<leader>:',
      function()
        MiniExtra.pickers.commands()
      end,
      'Commands',
    },
    {
      "<leader>'",
      function()
        MiniPick.builtin.resume()
      end,
      'Resume picker',
    },
    { 'gd', vim.lsp.buf.definition, 'Goto definition' },
    {
      'gR',
      function()
        MiniExtra.pickers.lsp({ scope = 'references' })
      end,
      'Goto references',
    },
    {
      'gi',
      function()
        MiniExtra.pickers.lsp({ scope = 'implementation' })
      end,
      'Goto implementation',
    },
    { 'gy', vim.lsp.buf.type_definition, 'Goto type definition' },
    {
      '<leader>E',
      function()
        MiniExtra.pickers.explorer()
      end,
      'File explorer',
    },
  }) do
    vim.keymap.set('n', spec[1], spec[2], { desc = spec[3] })
  end
end)

-- mini.snippets - Snippet management
later(function()
  add({ 'https://github.com/rafamadriz/friendly-snippets' })
  local snippets = require('mini.snippets')
  local config_path = vim.fn.stdpath('config')
  snippets.setup({
    snippets = {
      snippets.gen_loader.from_file(config_path .. '/snippets/global.json'),
      snippets.gen_loader.from_lang(),
    },
  })
  MiniSnippets.start_lsp_server()
end)

-- mini.keymap - Special key mappings for completion and pairs
later(function()
  require('mini.keymap').setup()
  -- Tab: accept completion item or jump snippet tabstop
  vim.keymap.set('i', '<Tab>', function()
    if vim.fn.pumvisible() == 1 then
      return '<C-y>'
    elseif MiniSnippets.session.get() then
      MiniSnippets.session.jump('next')
      return ''
    end
    return '<Tab>'
  end, { expr = true, desc = 'Accept completion or next tabstop' })
  -- S-Tab: jump snippet tabstop prev (use C-n/C-p to cycle completion menu)
  vim.keymap.set('i', '<S-Tab>', function()
    if MiniSnippets.session.get() then
      MiniSnippets.session.jump('prev')
      return ''
    end
    return '<S-Tab>'
  end, { expr = true, desc = 'Prev tabstop' })
  MiniKeymap.map_multistep('i', '<CR>', { 'pmenu_accept', 'minipairs_cr' })
  -- On <BS> just try to account for pairs
  MiniKeymap.map_multistep('i', '<BS>', { 'minipairs_bs' })
end)

-- mini.ai - Extend and create text objects
later(function()
  require('mini.ai').setup({
    n_lines = 500,
    custom_textobjects = {
      o = require('mini.ai').gen_spec.treesitter({
        a = { '@block.outer', '@conditional.outer', '@loop.outer' },
        i = { '@block.inner', '@conditional.inner', '@loop.inner' },
      }),
      f = require('mini.ai').gen_spec.treesitter({
        a = '@function.outer',
        i = '@function.inner',
      }),
      c = require('mini.ai').gen_spec.treesitter({
        a = '@class.outer',
        i = '@class.inner',
      }),
      t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' },
      d = { '%f[%d]%d+' },
      e = {
        {
          '%u[%l%d]+%f[^%l%d]',
          '%f[%S][%l%d]+%f[^%l%d]',
          '%f[%P][%l%d]+%f[^%l%d]',
          '^[%l%d]+%f[^%l%d]',
        },
        '^().*()$',
      },
      u = require('mini.ai').gen_spec.function_call(),
      U = require('mini.ai').gen_spec.function_call({ name_pattern = '[%w_]' }),
    },
  })
end)

-- mini.align - Align text interactively
later(function()
  require('mini.align').setup({
    -- Module mappings. Use `''` (empty string) to disable one.
    mappings = {
      start = 'ga',
      start_with_preview = 'gA',
    },
    -- Modifiers changing alignment steps and/or options
    modifiers = {
      -- Main option modifiers
      ['s'] = function(steps, opts)
        opts.split_pattern = '%s+'
        table.insert(steps.pre, require('mini.align').gen_step.trim())
      end,
      ['t'] = function(steps, opts)
        local ops = {
          '=',
          '=>',
          '//=',
          '!==',
          '==',
          '>=',
          '<=',
          '~=',
          '%=',
          '/=',
          '-=',
          '+=',
          '*=',
          '&=',
          '|=',
          '^=',
          ':=',
          '::=',
          '<-',
          '->',
          '>',
          '<',
        }
        opts.split_pattern = '(' .. table.concat(ops, '|') .. ')'
      end,
      [','] = function(steps, opts)
        opts.split_pattern = ','
        table.insert(steps.pre, require('mini.align').gen_step.trim())
      end,
      ['|'] = function(steps, opts)
        opts.split_pattern = '|'
        table.insert(steps.pre, require('mini.align').gen_step.trim())
      end,
      [' '] = function(steps, opts)
        table.insert(steps.pre, require('mini.align').gen_step.normalize_ws())
        opts.merge_delimiter = ' '
      end,
      -- Option-modifier modifiers
      ['j'] = function(steps, opts)
        opts.justify_side = 'left'
      end,
      ['J'] = function(steps, opts)
        opts.justify_side = 'right'
      end,
      ['m'] = function(steps, opts)
        opts.justify_side = 'center'
      end,
    },
    -- Default options controlling alignment process
    options = {
      split_pattern = '',
      justify_side = 'left',
      merge_delimiter = '',
    },
    -- Steps performed in order (use default steps)
  })
end)

-- mini.bracketed - Navigate with bracket mappings
later(function()
  require('mini.bracketed').setup({
    comment = { suffix = 'v' },
  })
end)

-- mini.bufremove - Remove buffers without closing windows
later(function()
  require('mini.bufremove').setup()
  vim.keymap.set('n', '<leader>bd', '<cmd>lua MiniBufremove.delete()<cr>', { desc = 'Delete buffer' })
  vim.keymap.set('n', '<leader>bD', '<cmd>lua MiniBufremove.delete(0, true)<cr>', { desc = 'Delete buffer (force)' })
  vim.keymap.set('n', '<leader>bw', '<cmd>lua MiniBufremove.wipeout()<cr>', { desc = 'Wipeout buffer' })
end)

-- mini.clue - Keybinding hints
later(function()
  local miniclue = require('mini.clue')
  miniclue.setup({
    triggers = {
      -- Leader triggers
      { mode = { 'n', 'x' }, keys = '<Leader>' },
      -- `[` and `]` keys
      { mode = 'n', keys = '[' },
      { mode = 'n', keys = ']' },
      -- Built-in completion
      { mode = 'i', keys = '<C-x>' },
      -- `g` key
      { mode = { 'n', 'x' }, keys = 'g' },
      -- Marks
      { mode = { 'n', 'x' }, keys = "'" },
      { mode = { 'n', 'x' }, keys = '`' },
      -- Registers
      { mode = { 'n', 'x' }, keys = '"' },
      { mode = { 'i', 'c' }, keys = '<C-r>' },
      -- Window commands
      { mode = 'n', keys = '<C-w>' },
      -- `z` key
      { mode = { 'n', 'x' }, keys = 'z' },
    },
    clues = {
      miniclue.gen_clues.square_brackets(),
      miniclue.gen_clues.builtin_completion(),
      miniclue.gen_clues.g(),
      miniclue.gen_clues.marks(),
      miniclue.gen_clues.registers(),
      miniclue.gen_clues.windows(),
      miniclue.gen_clues.z(),
      { mode = 'n', keys = '<Leader>b', desc = 'Buffer' },
      { mode = 'n', keys = '<Leader>v', desc = 'Visits' },
      { mode = 'n', keys = '<Leader>t', desc = 'Test' },

      { mode = 'n', keys = '<Leader>D', desc = 'Debug' },
      { mode = 'n', keys = '<Leader>g', desc = 'Git' },
      { mode = 'n', keys = '<Leader>K', desc = 'Kulala (HTTP)' },
      { mode = 'n', keys = '<Leader>O', desc = 'Overseer' },
      { mode = 'n', keys = '<Leader>S', desc = 'Session' },
      { mode = 'n', keys = '<Leader>T', desc = 'Toggle/Trim' },
      { mode = 'n', keys = '<Leader>X', desc = 'Trouble' },
    },
    window = {
      config = {},
      delay = 500,
      scroll_down = '<C-d>',
      scroll_up = '<C-u>',
    },
  })
end)

-- mini.cmdline - Better command line UI
later(function()
  require('mini.cmdline').setup({
    min_width = 60,
    max_height = 10,
    animation = true,
    use_icons = true,
    prompts = {
      [':'] = { prompt = '>' },
      ['/'] = { prompt = '/' },
      ['?'] = { prompt = '?' },
      ['=@'] = { prompt = '=' },
    },
    window = {
      config = { border = 'single' },
      relative = 'cursor',
    },
    completion = {
      enabled = true,
      max_items = 50,
      fuzzy = true,
      builtin_sources = {
        commands = 90,
        history = 80,
        file = 70,
        help = 60,
        lua = 50,
        shell = 40,
        var = 30,
      },
    },
    search = {
      show_count = true,
      highlight_matches = true,
    },
  })
end)

-- mini.comment - Comment operations
later(function()
  require('mini.comment').setup()
end)

-- mini.cursorword - Highlight word under cursor
later(function()
  require('mini.cursorword').setup()
end)

-- mini.indentscope - Indent scope visualization
later(function()
  require('mini.indentscope').setup({
    symbol = '╎',
    draw = {
      delay = 0,
      animation = function()
        return 0
      end,
    },
    options = {
      try_as_border = true,
    },
  })
end)

-- mini.diff - Git diff highlighting
later(function()
  local mini_diff = require('mini.diff')
  mini_diff.setup({
    view = {
      style = 'sign',
      signs = {
        add = '▌',
        change = '▌',
        delete = '▁',
      },
    },
    mappings = {
      apply = 'gh',
      reset = 'gH',
      textobject = 'gh',
    },
  })
  local toggle_diff = function()
    mini_diff.toggle_overlay(0)
  end
  vim.keymap.set('n', '<leader>gh', toggle_diff, { desc = 'Toggle diff overlay' })
end)

-- mini.git - Git integration (complements neogit)
later(function()
  require('mini.git').setup()

  -- Inspect / blame (unique to mini.git, no conflict with neogit)
  vim.keymap.set('n', '<leader>gB', '<cmd>lua MiniGit.show_range_history()<cr>', { desc = 'Git blame range' })
  vim.keymap.set('n', '<leader>gS', '<cmd>lua MiniGit.show_diff_source()<cr>', { desc = 'Git show diff source' })
end)

-- mini.hipatterns - Highlight patterns in text
later(function()
  local hipatterns = require('mini.hipatterns')
  hipatterns.setup({
    highlighters = {
      hex_color = hipatterns.gen_highlighter.hex_color(),
      fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
      hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
      todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
      note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },
    },
  })
end)

-- mini.jump - Improved f/F/t/T jumps
later(function()
  require('mini.jump').setup()
end)

-- mini.jump2d - Jump to any location on screen
later(function()
  local jump2d = require('mini.jump2d')
  jump2d.setup({
    spotter = jump2d.builtin_opts.word_start.spotter,
    labels = 'abcdefghijklmnopqrstuvwxyz',
    view = {
      n_steps_ahead = 999,
      dim = false,
    },
    mappings = { start_jumping = '' },
  })
  vim.keymap.set({ 'n', 'x', 'o' }, 'gw', function()
    jump2d.start(jump2d.builtin_opts.word_start)
  end, { desc = 'Jump to word start' })
  vim.keymap.set({ 'n', 'x', 'o' }, 'gl', function()
    jump2d.start(jump2d.builtin_opts.line_start)
  end, { desc = 'Jump to line start' })
end)

-- mini.move - Move lines and selections
later(function()
  require('mini.move').setup({
    mappings = {
      left = '<M-h>',
      right = '<M-l>',
      down = '<M-j>',
      up = '<M-k>',
      line_left = '<M-h>',
      line_right = '<M-l>',
      line_down = '<M-j>',
      line_up = '<M-k>',
    },
  })
end)

-- mini.operators - Text manipulation operators
later(function()
  require('mini.operators').setup({
    evaluate = { prefix = 'g=' },
    exchange = { prefix = 'gx', reindent_linewise = true },
    multiply = { prefix = 'gm' },
    replace = { prefix = 'gM', reindent_linewise = true },
    sort = { prefix = 'gs' },
  })
end)

-- mini.pairs - Auto pairs
later(function()
  require('mini.pairs').setup()
end)
-- Disable single quotes in Rust files
Config.new_autocmd('FileType', 'rust', function()
  vim.keymap.set('i', "'", "'", { buffer = true })
end, 'Disable single quotes in Rust')

-- mini.pick - General purpose interactive picker
later(function()
  require('mini.pick').setup({
    delay = { async = 10, busy = 50 },
    window = {
      config = { border = 'single' },
      prompt_prefix = '> ',
    },
    mappings = {
      send_all_to_qf = {
        char = '<C-q>',
        func = function()
          local matches = MiniPick.get_picker_matches()
          if not matches or not matches.all then
            return
          end
          MiniPick.default_choose_marked(matches.all)
          MiniPick.stop()
        end,
      },
    },
  })
  MiniPick = require('mini.pick')
end)

-- mini.splitjoin - Split and join arguments
later(function()
  require('mini.splitjoin').setup()
end)

-- mini.surround - Surround operations
later(function()
  require('mini.surround').setup({
    mappings = {
      add = 'ms',
      delete = 'md',
      find = 'mf',
      find_left = 'mF',
      highlight = 'mh',
      replace = 'mr',
      suffix_last = 'l',
      suffix_next = 'n',
    },
    respect_selection_type = true,
  })
end)

-- mini.trailspace - Trailing whitespace handling
later(function()
  require('mini.trailspace').setup()
  vim.keymap.set('n', '<leader>Tw', '<cmd>lua MiniTrailspace.trim()<cr>', { desc = 'Trim trailing whitespace' })
  vim.keymap.set(
    'n',
    '<leader>TW',
    '<cmd>lua MiniTrailspace.trim_last_lines()<cr>',
    { desc = 'Trim trailing empty lines' }
  )
end)

-- mini.visits - Track and navigate visited file locations
later(function()
  require('mini.visits').setup()

  vim.keymap.set('n', '<leader>vv', function()
    MiniVisits.select_path()
  end, { desc = 'Visits: Select recent location' })
  vim.keymap.set('n', '<leader>va', function()
    MiniVisits.add_label()
  end, { desc = 'Visits: Add label' })
  vim.keymap.set('n', '<leader>vr', function()
    MiniVisits.remove_label()
  end, { desc = 'Visits: Remove label' })
  vim.keymap.set('n', '<leader>vl', function()
    MiniVisits.select_label()
  end, { desc = 'Visits: Select labeled location' })
end)
