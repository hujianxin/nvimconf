-- ============================================================================
-- UI Plugins Configuration (plugin/70_ui.lua)
-- ============================================================================

local add = vim.pack.add
local later = Config.later

-- ============================================================================
-- Flash.nvim - Fast navigation
-- ============================================================================

later(function()
  add({ "https://github.com/folke/flash.nvim" })

  require("flash").setup({
    labels = "abcdefghijklmnopqrstuvwxyz",
    search = { mode = "fuzzy" },
    highlight = {
      backdrop = true,
      matches = true,
      priority = 5000,
      groups = {
        match = "FlashMatch",
        current = "FlashCurrent",
        backdrop = "FlashBackdrop",
        label = "FlashLabel",
      },
    },
    jump = {
      autojump = false,
      inclusive = true,
      post_jump = function()
        vim.cmd("normal! zz")
      end,
    },
    modes = {
      char = { enabled = false, jump_labels = true },
      search = { enabled = false },
    },
  })

  for _, spec in ipairs({
    {
      { "n", "x", "o" },
      "s",
      function()
        require("flash").jump()
      end,
      "Flash",
    },
    {
      { "n", "x", "o" },
      "S",
      function()
        require("flash").treesitter()
      end,
      "Flash Treesitter",
    },
    {
      { "o" },
      "r",
      function()
        require("flash").remote()
      end,
      "Remote Flash",
    },
    {
      { "o", "x" },
      "R",
      function()
        require("flash").treesitter_search()
      end,
      "Treesitter Search",
    },
    {
      { "c" },
      "<c-s>",
      function()
        require("flash").toggle()
      end,
      "Toggle Flash Search",
    },
  }) do
    vim.keymap.set(spec[1], spec[2], spec[3], { desc = spec[4] })
  end
end)

-- ============================================================================
-- Trouble.nvim - Diagnostics and quickfix
-- ============================================================================

local function trouble_cmd(cmd)
  if not package.loaded["trouble"] then
    add({ "https://github.com/folke/trouble.nvim" })
    require("trouble").setup({
      icons = {
        indent = { fold_open = "", fold_closed = "" },
        folder_open = "",
        folder_closed = "",
        kinds = {},
      },
    })
  end
  vim.cmd(cmd)
end

for _, spec in ipairs({
  { "<leader>XX", "Trouble diagnostics toggle", "Diagnostics" },
  { "<leader>Xx", "Trouble diagnostics toggle filter.buf=0", "Buffer Diagnostics" },
  { "<leader>Xs", "Trouble symbols toggle focus=false", "Symbols" },
  { "<leader>Xl", "Trouble lsp toggle focus=false win.position=right", "LSP Definitions/References" },
  { "<leader>XL", "Trouble loclist toggle", "Location List" },
  { "<leader>XQ", "Trouble qflist toggle", "Quickfix List" },
}) do
  vim.keymap.set("n", spec[1], function()
    trouble_cmd(spec[2])
  end, { desc = spec[3] })
end

-- ============================================================================
-- Grug-far - Search and replace
-- ============================================================================

local function grugfar(fn, ...)
  if not package.loaded["grug-far"] then
    add({ "https://github.com/MagicDuck/grug-far.nvim" })
    require("grug-far").setup({ windowCreationCommand = "vsplit" })
  end
  require("grug-far")[fn](...)
end

vim.keymap.set("n", "<M-S-s>", function()
  grugfar("open")
end, { desc = "Replace in files" })
vim.keymap.set("n", "<M-S-w>", function()
  grugfar("open", { prefills = { search = vim.fn.expand("<cword>") } })
end, { desc = "Replace current word" })
vim.keymap.set("v", "<M-S-w>", function()
  grugfar("with_visual_selection")
end, { desc = "Replace selection" })
vim.keymap.set("n", "<M-S-f>", function()
  grugfar("open", { prefills = { paths = vim.fn.expand("%") } })
end, { desc = "Replace in current file" })
