-- ============================================================================
-- Neovide GUI Configuration (plugin/65_neovide.lua)
-- ============================================================================
-- macOS-style keyboard shortcuts and font scaling for the Neovide GUI client.
-- No-op when not running inside Neovide.

if not vim.g.neovide then
  return
end

-- ============================================================================
-- Visual & input settings
-- ============================================================================

vim.g.neovide_position_animation_length = 0
vim.g.neovide_cursor_animation_length = 0.00
vim.g.neovide_cursor_trail_size = 0
vim.g.neovide_cursor_animate_in_insert_mode = false
vim.g.neovide_cursor_animate_command_line = false
vim.g.neovide_scroll_animation_far_lines = 0
vim.g.neovide_scroll_animation_length = 0.00
vim.g.neovide_padding_top = 0
vim.g.neovide_padding_bottom = 0
vim.g.neovide_padding_right = 0
vim.g.neovide_padding_left = 0
vim.g.neovide_input_macos_option_key_is_meta = 'only_left'
vim.g.neovide_input_ime = true

-- ============================================================================
-- IME handling
-- ============================================================================

local function set_ime(args)
  if args.event:match('Enter$') then
    vim.g.neovide_input_ime = true
  else
    vim.g.neovide_input_ime = false
  end
end

local ime_input = vim.api.nvim_create_augroup('ime_input', { clear = true })

vim.api.nvim_create_autocmd({ 'InsertEnter', 'InsertLeave' }, {
  group = ime_input,
  pattern = '*',
  callback = set_ime,
})

vim.api.nvim_create_autocmd({ 'CmdlineEnter', 'CmdlineLeave' }, {
  group = ime_input,
  pattern = '[/\\?]',
  callback = set_ime,
})

-- ============================================================================
-- Font
-- ============================================================================

local DEFAULT_FONT = 'Maple Mono NF:h13'

vim.o.guifont = DEFAULT_FONT

local function guifontscale(n)
  if type(n) ~= 'number' then
    return
  end
  local current_size = vim.o.guifont:match(':h(%d+)$')
  if not current_size then
    return
  end
  local new_size = tonumber(current_size) + n
  if new_size < 1 then
    new_size = 1
  end
  vim.o.guifont = vim.o.guifont:gsub(':h%d+$', ':h' .. new_size)
end

-- ============================================================================
-- Keymaps: File operations
-- ============================================================================

vim.keymap.set('n', '<D-o>', ':browse confirm e<CR>', { silent = true })
vim.keymap.set('v', '<D-o>', '<Esc><D-o>gv', { silent = true })
vim.keymap.set('i', '<D-o>', '<C-O><D-o>', { silent = true })
vim.keymap.set('c', '<D-o>', '<C-C><D-o>', { silent = true })
vim.keymap.set('o', '<D-o>', '<Esc><D-o>', { silent = true })

vim.keymap.set('n', '<D-w>', ':confirm bd<CR>', { silent = true })
vim.keymap.set('v', '<D-w>', '<Esc><D-w>gv', { silent = true })
vim.keymap.set('i', '<D-w>', '<C-O><D-w>', { silent = true })
vim.keymap.set('c', '<D-w>', '<C-C><D-w>', { silent = true })
vim.keymap.set('o', '<D-w>', '<Esc><D-w>', { silent = true })

vim.keymap.set('n', '<D-s>', function()
  if vim.fn.expand('%') == '' then
    vim.cmd('browse confirm w')
  else
    vim.cmd('confirm w')
  end
end, { silent = true })
vim.keymap.set('v', '<D-s>', '<Esc><D-s>gv', { silent = true })
vim.keymap.set('i', '<D-s>', '<C-O><D-s>', { silent = true })
vim.keymap.set('c', '<D-s>', '<C-C><D-s>', { silent = true })
vim.keymap.set('o', '<D-s>', '<Esc><D-s>', { silent = true })

vim.keymap.set('n', '<D-S-s>', ':browse confirm saveas<CR>', { silent = true })
vim.keymap.set('v', '<D-S-s>', '<Esc><D-S-s>gv', { silent = true })
vim.keymap.set('i', '<D-S-s>', '<C-O><D-S-s>', { silent = true })
vim.keymap.set('c', '<D-S-s>', '<C-C><D-S-s>', { silent = true })
vim.keymap.set('o', '<D-S-s>', '<Esc><D-S-s>', { silent = true })

-- ============================================================================
-- Keymaps: Clipboard
-- ============================================================================

vim.keymap.set('v', '<D-c>', '"+y', { noremap = true, silent = true })
vim.keymap.set({ 'n', 'v' }, '<D-v>', '"+p', { noremap = true, silent = true })
vim.keymap.set('i', '<D-v>', '<C-r>+', { noremap = true, silent = true })
vim.keymap.set('c', '<D-v>', '<C-r><C-o>+', { noremap = true })
vim.keymap.set('v', '<D-x>', '"+x', { noremap = true, silent = true })

vim.keymap.set('n', '<D-a>', 'ggVG', { noremap = true, silent = true })
vim.keymap.set('v', '<D-a>', '<Esc><D-a>', { silent = true })
vim.keymap.set('i', '<D-a>', '<Esc><D-a>', { silent = true })
vim.keymap.set('c', '<D-a>', '<C-C><D-a>', { silent = true })
vim.keymap.set('o', '<D-a>', '<Esc><D-a>', { silent = true })

-- ============================================================================
-- Keymaps: Edit
-- ============================================================================

vim.keymap.set('n', '<D-z>', 'u', { noremap = true, silent = true })
vim.keymap.set('v', '<D-z>', '<Esc><D-z>gv', { silent = true })
vim.keymap.set('i', '<D-z>', '<C-O><D-z>', { silent = true })
vim.keymap.set('c', '<D-z>', '<C-C><D-z>', { silent = true })
vim.keymap.set('o', '<D-z>', '<Esc><D-z>', { silent = true })

vim.keymap.set('n', '<D-S-z>', '<C-r>', { noremap = true, silent = true })
vim.keymap.set('v', '<D-S-z>', '<Esc><D-S-z>gv', { silent = true })
vim.keymap.set('i', '<D-S-z>', '<C-O><D-S-z>', { silent = true })
vim.keymap.set('c', '<D-S-z>', '<C-C><D-S-z>', { silent = true })
vim.keymap.set('o', '<D-S-z>', '<Esc><D-S-z>', { silent = true })

-- ============================================================================
-- Keymaps: Search
-- ============================================================================

vim.keymap.set('n', '<D-f>', '/', { noremap = true })
vim.keymap.set('v', '<D-f>', '<Esc><D-f>', { silent = true })
vim.keymap.set('i', '<D-f>', '<Esc><D-f>', { silent = true })
vim.keymap.set('c', '<D-f>', '<C-C><D-f>', { silent = true })
vim.keymap.set('o', '<D-f>', '<Esc><D-f>', { silent = true })

vim.keymap.set('n', '<D-g>', 'n', { noremap = true, silent = true })
vim.keymap.set('v', '<D-g>', '<Esc><D-g>', { silent = true })
vim.keymap.set('i', '<D-g>', '<C-O><D-g>', { silent = true })
vim.keymap.set('c', '<D-g>', '<C-C><D-g>', { silent = true })
vim.keymap.set('o', '<D-g>', '<Esc><D-g>', { silent = true })

vim.keymap.set('n', '<D-S-g>', 'N', { noremap = true, silent = true })
vim.keymap.set('v', '<D-S-g>', '<Esc><D-S-g>', { silent = true })
vim.keymap.set('i', '<D-S-g>', '<C-O><D-S-g>', { silent = true })
vim.keymap.set('c', '<D-S-g>', '<C-C><D-S-g>', { silent = true })
vim.keymap.set('o', '<D-S-g>', '<Esc><D-S-g>', { silent = true })

-- ============================================================================
-- Keymaps: Font scaling
-- ============================================================================

local all_modes = { 'n', 'v', 'i', 'c', 'o', 't' }

vim.keymap.set(all_modes, '<D-=>', function()
  guifontscale(1)
end, { noremap = true, silent = true })

vim.keymap.set(all_modes, '<D-->', function()
  guifontscale(-1)
end, { noremap = true, silent = true })

vim.keymap.set(all_modes, '<D-0>', function()
  vim.o.guifont = DEFAULT_FONT
end, { noremap = true, silent = true })
