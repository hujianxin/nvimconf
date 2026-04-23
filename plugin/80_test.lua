-- ============================================================================
-- Test Configuration (plugin/80_test.lua)
-- ============================================================================

local add = vim.pack.add

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
