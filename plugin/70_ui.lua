-- ============================================================================
-- UI Plugins Configuration (plugin/70_ui.lua)
-- ============================================================================

local add = vim.pack.add
local later, on_filetype = Config.later, Config.on_filetype

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

  vim.keymap.set({ "n", "x", "o" }, "s", function()
    require("flash").jump()
  end, { desc = "Flash" })
  vim.keymap.set({ "n", "x", "o" }, "S", function()
    require("flash").treesitter()
  end, { desc = "Flash Treesitter" })
  vim.keymap.set("o", "r", function()
    require("flash").remote()
  end, { desc = "Remote Flash" })
  vim.keymap.set({ "o", "x" }, "R", function()
    require("flash").treesitter_search()
  end, { desc = "Treesitter Search" })
  vim.keymap.set("c", "<c-s>", function()
    require("flash").toggle()
  end, { desc = "Toggle Flash Search" })
end)

-- ============================================================================
-- Trouble.nvim - Diagnostics and quickfix
-- ============================================================================

later(function()
  add({
    "https://github.com/folke/trouble.nvim",
    "https://github.com/nvim-mini/mini.icons",
  })

  require("trouble").setup({
    icons = {
      indent = { fold_open = "", fold_closed = "" },
      folder_open = "",
      folder_closed = "",
      kinds = {},
    },
  })

  vim.keymap.set("n", "<leader>XX", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics" })
  vim.keymap.set("n", "<leader>Xx", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics" })
  vim.keymap.set("n", "<leader>Xs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols" })
  vim.keymap.set(
    "n",
    "<leader>Xl",
    "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
    { desc = "LSP Definitions/References" }
  )
  vim.keymap.set("n", "<leader>XL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List" })
  vim.keymap.set("n", "<leader>XQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List" })
end)

-- ============================================================================
-- Grug-far - Search and replace
-- ============================================================================

later(function()
  add({ "https://github.com/MagicDuck/grug-far.nvim" })

  require("grug-far").setup({
    windowCreationCommand = "vsplit",
  })

  vim.keymap.set("n", "<M-S-s>", function()
    require("grug-far").open()
  end, { desc = "Replace in files (grug-far)" })
  vim.keymap.set("n", "<M-S-w>", function()
    require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
  end, { desc = "Replace current word" })
  vim.keymap.set("v", "<M-S-w>", function()
    require("grug-far").with_visual_selection()
  end, { desc = "Replace selection" })
  vim.keymap.set("n", "<M-S-f>", function()
    require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } })
  end, { desc = "Replace in current file" })
end)

-- ============================================================================
-- Quicker.nvim - Enhanced quickfix
-- ============================================================================

on_filetype("qf", function()
  add({ "https://github.com/stevearc/quicker.nvim" })
  require("quicker").setup()
end)
