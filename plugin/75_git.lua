-- ============================================================================
-- Git Configuration (plugin/75_git.lua)
-- ============================================================================
--
--   <leader>g keymap overview (see also plugin/30_mini.lua for mini.diff/mini.git)
--
--          Inspect                 Daily workflow         Stash         Diffview
--       ┌───────────────┐    ┌─────────────────────┐    ┌─────────┐    ┌──────────────────────┐
--       │ gb  blame     │    │ gc  commit          │    │ gw save │    │ go  open             │
--       │ gB  blame L   │    │ ga  amend           │    │ gW pop  │    │ gO  open vs HEAD     │
--       │ gS  diff src  │    │ gp  push            │    └─────────┘    │ gf  file history     │
--       │ gd  toggle    │    │ gP  pull --rebase   │                   │ gq  close            │
--       │ gh  toggle    │    │ gl  log --oneline   │                   │ gF  focus panel      │
--       └───────────────┘    │ gL  log --graph     │                   │ gt  toggle panel     │
--                            │ gs  status          │                   │ gr  refresh          │
--                            └─────────────────────┘                   │ gH  this file vs rev │
--                                                                      └──────────────────────┘
--

local add = vim.pack.add
local later = Config.later

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
-- Diffview.nvim - Git diff viewer
-- ============================================================================

later(function()
  add({ 'https://github.com/sindrets/diffview.nvim' })
  require('diffview').setup({
    view = {
      default = { layout = 'diff2_horizontal' },
      merge_tool = { layout = 'diff3_horizontal' },
    },
    file_panel = { win_config = { width = 35 } },
    keymaps = {
      view = { { 'n', 'q', '<Cmd>DiffviewClose<CR>', { desc = 'Close' } } },
      file_panel = { { 'n', 'q', '<Cmd>DiffviewClose<CR>', { desc = 'Close' } } },
    },
  })
end)

vim.keymap.set('n', '<leader>go', ':DiffviewOpen<CR>', { desc = 'Git diffview open' })
vim.keymap.set('n', '<leader>gO', ':DiffviewOpen HEAD<CR>', { desc = 'Git diffview vs HEAD' })
vim.keymap.set('n', '<leader>gf', ':DiffviewFileHistory<CR>', { desc = 'Git file history' })
vim.keymap.set('n', '<leader>gq', ':DiffviewClose<CR>', { desc = 'Git diffview close' })
vim.keymap.set('n', '<leader>gF', ':DiffviewFocusFiles<CR>', { desc = 'Git focus file panel' })
vim.keymap.set('n', '<leader>gt', ':DiffviewToggleFiles<CR>', { desc = 'Git toggle file panel' })
vim.keymap.set('n', '<leader>gr', ':DiffviewRefresh<CR>', { desc = 'Git diffview refresh' })

vim.keymap.set('n', '<leader>gH', function()
  local rev = vim.fn.input('Diff current file vs: ')
  if rev ~= '' then
    vim.cmd('DiffviewOpen ' .. rev .. ' -- %')
  end
end, { desc = 'Git diff current file vs revision' })
