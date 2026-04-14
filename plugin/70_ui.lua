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
-- Trouble.nvim - Diagnostics and quickfix (lazy-loaded on command)
-- ============================================================================

local trouble_loaded = false
local function ensure_trouble()
  if trouble_loaded then
    return
  end
  trouble_loaded = true
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
end

vim.keymap.set("n", "<leader>XX", function()
  ensure_trouble()
  vim.cmd("Trouble diagnostics toggle")
end, { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>Xx", function()
  ensure_trouble()
  vim.cmd("Trouble diagnostics toggle filter.buf=0")
end, { desc = "Buffer Diagnostics" })
vim.keymap.set("n", "<leader>Xs", function()
  ensure_trouble()
  vim.cmd("Trouble symbols toggle focus=false")
end, { desc = "Symbols" })
vim.keymap.set("n", "<leader>Xl", function()
  ensure_trouble()
  vim.cmd("Trouble lsp toggle focus=false win.position=right")
end, { desc = "LSP Definitions/References" })
vim.keymap.set("n", "<leader>XL", function()
  ensure_trouble()
  vim.cmd("Trouble loclist toggle")
end, { desc = "Location List" })
vim.keymap.set("n", "<leader>XQ", function()
  ensure_trouble()
  vim.cmd("Trouble qflist toggle")
end, { desc = "Quickfix List" })

-- ============================================================================
-- Grug-far - Search and replace (lazy-loaded on command)
-- ============================================================================

local grugfar_loaded = false
local function ensure_grugfar()
  if grugfar_loaded then
    return
  end
  grugfar_loaded = true
  add({ "https://github.com/MagicDuck/grug-far.nvim" })

  require("grug-far").setup({
    windowCreationCommand = "vsplit",
  })
end

vim.keymap.set("n", "<M-S-s>", function()
  ensure_grugfar()
  require("grug-far").open()
end, { desc = "Replace in files (grug-far)" })
vim.keymap.set("n", "<M-S-w>", function()
  ensure_grugfar()
  require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
end, { desc = "Replace current word" })
vim.keymap.set("v", "<M-S-w>", function()
  ensure_grugfar()
  require("grug-far").with_visual_selection()
end, { desc = "Replace selection" })
vim.keymap.set("n", "<M-S-f>", function()
  ensure_grugfar()
  require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } })
end, { desc = "Replace in current file" })

-- ============================================================================
-- Quicker.nvim - Enhanced quickfix
-- ============================================================================

on_filetype("qf", function()
  add({ "https://github.com/stevearc/quicker.nvim" })
  require("quicker").setup()
end)
