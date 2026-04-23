-- ============================================================================
-- UI & Tools Configuration (plugin/70_tools.lua)
-- ============================================================================

local add = vim.pack.add
local later, on_filetype = Config.later, Config.on_filetype

-- ============================================================================
-- Overseer - Task runner
-- ============================================================================

local function overseer(cmd)
  if not package.loaded['overseer'] then
    add({ 'https://github.com/stevearc/overseer.nvim' })
    require('overseer').setup({
      log_level = vim.log.levels.TRACE,
      component_aliases = {
        default = {
          'on_exit_set_status',
          { 'on_complete_notify', system = 'unfocused' },
          { 'on_complete_dispose', require_view = { 'SUCCESS', 'FAILURE' } },
        },
      },
    })
    vim.cmd.cnoreabbrev('OS OverseerShell')
    vim.cmd.cnoreabbrev('make Make')
  end
  if type(cmd) == 'function' then
    cmd()
  else
    vim.cmd(cmd)
  end
end

for _, spec in ipairs({
  { '<leader>Ot', 'OverseerToggle!', 'Toggle' },
  { '<leader>Or', 'OverseerRun', 'Run' },
  { '<leader>Os', 'OverseerShell', 'Shell' },
  { '<leader>OT', 'OverseerTaskAction', 'Task action' },
}) do
  vim.keymap.set('n', spec[1], function()
    overseer(spec[2])
  end, { desc = spec[3] })
end

vim.keymap.set('n', '<leader>OR', function()
  overseer(function()
    local tasks = require('overseer').list_tasks({ recent = true })
    if #tasks > 0 then
      tasks[1]:restart()
    else
      vim.notify('No recent task', vim.log.levels.WARN)
    end
  end)
end, { desc = 'Rerun last' })

vim.keymap.set('n', '<leader>Od', function()
  overseer(function()
    local o = require('overseer')
    local tasks =
      o.list_tasks({ sort = require('overseer.task_list').sort_finished_recently, include_ephemeral = true })
    if vim.tbl_isempty(tasks) then
      vim.notify('No tasks', vim.log.levels.WARN)
    else
      o.run_action(tasks[1])
    end
  end)
end, { desc = 'Do quick action' })

vim.api.nvim_create_user_command('Make', function(params)
  overseer(function()
    local cmd, num_subs = vim.o.makeprg:gsub('%$%*', params.args)
    if num_subs == 0 then
      cmd = cmd .. ' ' .. params.args
    end
    require('overseer')
      .new_task({
        cmd = vim.fn.expandcmd(cmd),
        components = { { 'on_output_quickfix', open = not params.bang, open_height = 8 }, 'unique', 'default' },
      })
      :start()
  end)
end, { desc = 'Run makeprg as Overseer task', nargs = '*', bang = true })

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
    {
      { 'n', 'x' },
      '<C-S-n>',
      function()
        mc.matchAddCursor(-1)
      end,
    },
    {
      { 'n', 'x' },
      '<C-S-s>',
      function()
        mc.matchSkipCursor(-1)
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
-- ToggleTerm - Terminal
-- ============================================================================

later(function()
  local last_term_num = 1
  local function ensure_toggleterm()
    if not package.loaded['toggleterm'] then
      add({ 'https://github.com/akinsho/toggleterm.nvim' })
      require('toggleterm').setup({
        size = 20,
        hide_numbers = true,
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        terminal_mappings = true,
        persist_size = true,
        persist_mode = true,
        direction = 'float',
        close_on_exit = true,
        shell = vim.o.shell,
        auto_scroll = true,
        float_opts = { border = 'curved', winblend = 0 },
      })
    end
  end

  vim.keymap.set({ 'n', 'i', 't' }, '<d-j>', function()
    ensure_toggleterm()
    local target = vim.v.count > 0 and vim.v.count or last_term_num
    if vim.v.count > 0 then
      last_term_num = target
    end
    vim.cmd.execute("'" .. target .. "ToggleTerm direction=horizontal'")
  end, { desc = 'Toggle terminal' })

  vim.keymap.set('t', '<esc><esc>', [[<C-\><C-n>]], { desc = 'Exit terminal mode' })
end)

-- ============================================================================
-- Auto-save
-- ============================================================================

Config.new_autocmd({ 'InsertLeave', 'TextChanged' }, '*', function()
  add({ 'https://github.com/okuuva/auto-save.nvim' })
  require('auto-save').setup()
end, 'Setup auto-save', { once = true })

-- ============================================================================
-- LazyGit
-- ============================================================================

vim.keymap.set('n', '<c-g>', function()
  if not package.loaded['lazygit'] then
    add({ 'https://github.com/kdheepak/lazygit.nvim', 'https://github.com/nvim-lua/plenary.nvim' })
  end
  vim.cmd('LazyGit')
end, { desc = 'LazyGit' })

-- ============================================================================
-- Kulala (HTTP client)
-- ============================================================================

on_filetype({ 'http', 'rest' }, function()
  add({ 'https://github.com/mistweaverco/kulala.nvim' })
  require('kulala').setup({ global_keymaps = true, global_keymaps_prefix = '<leader>K', kulala_keymaps_prefix = '' })
end)

-- ============================================================================
-- CodeDiff - VSCode-style diff viewer
-- ============================================================================

local function ensure_codediff()
  if not package.loaded['codediff'] then
    add({ 'https://github.com/esmuellert/codediff.nvim' })
    require('codediff').setup({
      diff = {
        layout = 'side-by-side',
        disable_inlay_hints = true,
        max_computation_time_ms = 5000,
        ignore_trim_whitespace = false,
        jump_to_first_change = true,
        highlight_priority = 100,
        compute_moves = false,
      },
      explorer = {
        position = 'left',
        width = 40,
        indent_markers = true,
        initial_focus = 'explorer',
        view_mode = 'list',
        flatten_dirs = true,
        file_filter = { ignore = { '.git/**', '.jj/**', 'node_modules/**', 'target/**', 'dist/**' } },
        focus_on_select = false,
        visible_groups = { staged = true, unstaged = true, conflicts = true },
      },
    })
  end
end

vim.api.nvim_create_user_command('CodeDiff', function(params)
  ensure_codediff()
  vim.cmd('CodeDiff ' .. params.args)
end, { nargs = '*', complete = 'file', desc = 'CodeDiff explorer' })

vim.api.nvim_create_user_command('CodeDiffHead', function()
  ensure_codediff()
  vim.cmd('CodeDiff HEAD')
end, { desc = 'CodeDiff with HEAD' })

vim.api.nvim_create_user_command('CodeDiffHistory', function()
  ensure_codediff()
  vim.cmd('CodeDiff history')
end, { desc = 'CodeDiff history' })

for _, spec in ipairs({
  { '<leader>Cd', 'CodeDiff', 'CodeDiff files' },
  { '<leader>Ch', 'CodeDiffHistory', 'CodeDiff history' },
  { '<leader>CH', 'CodeDiffHead', 'CodeDiff with HEAD' },
}) do
  vim.keymap.set('n', spec[1], ':' .. spec[2] .. '<CR>', { desc = spec[3] })
end

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
-- Trouble.nvim - Diagnostics and quickfix
-- ============================================================================

local function trouble_cmd(cmd)
  if not package.loaded['trouble'] then
    add({ 'https://github.com/folke/trouble.nvim' })
    require('trouble').setup({
      icons = {
        indent = { fold_open = '', fold_closed = '' },
        folder_open = '',
        folder_closed = '',
        kinds = {},
      },
    })
  end
  vim.cmd(cmd)
end

for _, spec in ipairs({
  { '<leader>XX', 'Trouble diagnostics toggle', 'Diagnostics' },
  { '<leader>Xx', 'Trouble diagnostics toggle filter.buf=0', 'Buffer Diagnostics' },
  { '<leader>Xs', 'Trouble symbols toggle focus=false', 'Symbols' },
  { '<leader>Xl', 'Trouble lsp toggle focus=false win.position=right', 'LSP Definitions/References' },
  { '<leader>XL', 'Trouble loclist toggle', 'Location List' },
  { '<leader>XQ', 'Trouble qflist toggle', 'Quickfix List' },
}) do
  vim.keymap.set('n', spec[1], function()
    trouble_cmd(spec[2])
  end, { desc = spec[3] })
end

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
