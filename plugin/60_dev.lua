-- ============================================================================
-- Dev Tools Configuration (plugin/60_dev.lua)
-- ============================================================================
-- Git, task runner, terminal, test, debug, and HTTP client.
-- All are lazy-loaded: nothing installs until first use.

local add = vim.pack.add
local later = Config.later
local on_filetype = Config.on_filetype

-- ============================================================================
-- Git
-- ============================================================================

-- LazyGit
local function ensure_lazygit()
  if not package.loaded['lazygit'] then
    add({ 'https://github.com/kdheepak/lazygit.nvim', 'https://github.com/nvim-lua/plenary.nvim' })
  end
end

vim.keymap.set('n', '<c-g>', function()
  ensure_lazygit()
  vim.cmd('LazyGit')
end, { desc = 'LazyGit' })

vim.keymap.set('n', '<leader>gg', function()
  ensure_lazygit()
  vim.cmd('LazyGit')
end, { desc = 'LazyGit' })

-- Fugitive.vim (provides :Git, :G, :Gvdiffsplit, etc.)
later(function()
  add({ 'https://github.com/tpope/vim-fugitive' })
end)

-- Daily workflow
vim.keymap.set('n', '<leader>gs', ':G<CR>', { desc = 'Git status' })
vim.keymap.set('n', '<leader>gl', ':G log --oneline<CR>', { desc = 'Git log (oneline)' })
vim.keymap.set('n', '<leader>gL', ':G log --oneline --graph --all<CR>', { desc = 'Git log (graph all)' })

-- Diff & blame
vim.keymap.set('n', '<leader>gb', ':G blame<CR>', { desc = 'Git blame' })
vim.keymap.set('n', '<leader>gD', ':Gvdiffsplit<CR>', { desc = 'Git diff vs index' })
vim.keymap.set('n', '<leader>gO', ':Gvdiffsplit HEAD<CR>', { desc = 'Git diff vs HEAD' })
vim.keymap.set('n', '<leader>go', function()
  local rev = vim.fn.input('Diff current file vs: ')
  if rev ~= '' then
    vim.cmd('Gvdiffsplit ' .. rev .. ':%')
  end
end, { desc = 'Git diff current file vs revision' })
vim.keymap.set('n', '<leader>gf', ':0Gclog<CR>', { desc = 'Git file history' })
vim.keymap.set('n', '<leader>gq', ':diffoff!<CR>:close<CR>', { desc = 'Close diff window' })

-- Browse
vim.keymap.set('n', '<leader>gS', ':Gedit HEAD:%<CR>', { desc = 'Open HEAD version' })

-- ============================================================================
-- Task Runner & Terminal
-- ============================================================================

-- Overseer
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

-- ToggleTerm
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
-- Test
-- ============================================================================

local function test_cmd(cmd)
  if not package.loaded['test'] then
    add({
      'https://github.com/tpope/vim-dispatch',
      'https://github.com/vim-test/vim-test',
    })
    vim.g['test#strategy'] = 'neovim_sticky'
    vim.g['test#preserve_screen'] = 0
    vim.g['test#neovim_sticky#kill_previous'] = 1
    vim.g['test#neovim_sticky#reopen_window'] = 1
  end
  vim.cmd(cmd)
end

for _, spec in ipairs({
  { 'TestNearest', 'Run nearest test' },
  { 'TestFile', 'Run test file' },
  { 'TestSuite', 'Run test suite' },
  { 'TestLast', 'Run last test' },
  { 'TestVisit', 'Visit last test' },
}) do
  vim.api.nvim_create_user_command(spec[1], function()
    test_cmd(spec[1])
  end, { desc = spec[2] })
end

for _, spec in ipairs({
  { '<leader>tn', 'TestNearest', 'Test nearest' },
  { '<leader>tt', 'TestNearest', 'Test nearest' },
  { '<leader>tf', 'TestFile', 'Test file' },
  { '<leader>ts', 'TestSuite', 'Test suite' },
  { '<leader>tl', 'TestLast', 'Test last' },
  { '<leader>tv', 'TestVisit', 'Test visit' },
}) do
  vim.keymap.set('n', spec[1], ':' .. spec[2] .. '<CR>', { desc = spec[3] })
end

-- ============================================================================
-- DAP
-- ============================================================================

local function ensure_dap()
  if package.loaded['dap'] then
    return
  end
  add({
    'https://github.com/mfussenegger/nvim-dap',
    'https://github.com/igorlfs/nvim-dap-view',
    'https://github.com/nvim-neotest/nvim-nio',
  })

  local dap = require('dap')
  local dapview = require('dap-view')
  dapview.setup({ winbar = { controls = { enabled = true } } })

  dap.listeners.after.event_initialized['dap-view'] = function()
    dapview.open()
  end
  dap.listeners.after.event_terminated['dap-view'] = function()
    dapview.close()
  end
  dap.listeners.after.event_exited['dap-view'] = function()
    dapview.close()
  end

  for _, spec in ipairs({
    { 'DapBreakpoint', '●' },
    { 'DapBreakpointCondition', '◆' },
    { 'DapBreakpointRejected', '✗' },
    { 'DapLogPoint', '◆' },
    { 'DapStopped', '→', 'DapStoppedLine' },
  }) do
    local opts = { text = spec[2], texthl = spec[1] }
    if spec[3] then
      opts.linehl = spec[3]
    end
    vim.fn.sign_define(spec[1], opts)
  end

  dap.adapters.delve = {
    type = 'server',
    port = '${port}',
    executable = { command = 'dlv', args = { 'dap', '-l', '127.0.0.1:${port}' } },
  }
  dap.configurations.go = {
    { name = 'Debug', type = 'delve', request = 'launch', program = '${file}' },
    { name = 'Debug test', type = 'delve', request = 'launch', mode = 'test', program = '${file}' },
  }

  dap.adapters.codelldb = {
    type = 'server',
    port = '${port}',
    executable = { command = 'codelldb', args = { '--port', '${port}' } },
  }
  for _, ft in ipairs({ 'rust', 'zig', 'c', 'cpp' }) do
    dap.configurations[ft] = {
      {
        name = 'Debug',
        type = 'codelldb',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
      },
    }
  end
end

for _, spec in ipairs({
  {
    '<leader>Db',
    function()
      require('dap').toggle_breakpoint()
    end,
    'Toggle breakpoint',
  },
  {
    '<leader>DB',
    function()
      require('dap').set_breakpoint(vim.fn.input('Condition: '))
    end,
    'Conditional breakpoint',
  },
  {
    '<leader>Dc',
    function()
      require('dap').continue()
    end,
    'Continue/start',
  },
  {
    '<leader>DC',
    function()
      require('dap').run_to_cursor()
    end,
    'Run to cursor',
  },
  {
    '<leader>Ds',
    function()
      require('dap').step_over()
    end,
    'Step over',
  },
  {
    '<leader>Di',
    function()
      require('dap').step_into()
    end,
    'Step into',
  },
  {
    '<leader>Do',
    function()
      require('dap').step_out()
    end,
    'Step out',
  },
  {
    '<leader>Dr',
    function()
      require('dap').repl.open()
    end,
    'REPL',
  },
  {
    '<leader>De',
    function()
      require('dap.ui.widgets').hover()
    end,
    'Evaluate',
  },
  {
    '<leader>Dp',
    function()
      require('dap').terminate()
      require('dap').repl.close()
      require('dap-view').close()
    end,
    'Stop debugging',
  },
  {
    '<leader>Dv',
    function()
      require('dap-view').toggle()
    end,
    'Toggle DAP view',
  },
}) do
  vim.keymap.set('n', spec[1], function()
    ensure_dap()
    spec[2]()
  end, { desc = spec[3] })
end

for _, spec in ipairs({
  {
    'Debug',
    function()
      require('dap').continue()
    end,
    'Start debug session',
  },
  {
    'Breakpoint',
    function()
      require('dap').toggle_breakpoint()
    end,
    'Toggle breakpoint',
  },
  {
    'DapView',
    function()
      require('dap-view').toggle()
    end,
    'Toggle DAP view',
  },
}) do
  vim.api.nvim_create_user_command(spec[1], function()
    ensure_dap()
    spec[2]()
  end, { desc = spec[3] })
end

-- ============================================================================
-- Kulala (HTTP client)
-- ============================================================================

on_filetype({ 'http', 'rest' }, function()
  add({ 'https://github.com/mistweaverco/kulala.nvim' })
  require('kulala').setup({ global_keymaps = true, global_keymaps_prefix = '<leader>K', kulala_keymaps_prefix = '' })
end)
