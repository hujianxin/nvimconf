-- ============================================================================
-- Key Mappings (plugin/20_keymaps.lua)
-- ============================================================================

-- Better visual mode indenting
vim.keymap.set("v", "<", "<gv", { desc = "Indent left" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right" })

-- Clear search highlight
vim.keymap.set("n", "<ESC>", ":nohlsearch<CR>", { silent = true, desc = "Clear search highlight" })

-- Quick quit
vim.keymap.set("n", "zq", ":q<CR>", { silent = true, desc = "Quit" })

-- Incremental selection (treesitter/LSP)
vim.keymap.set({ "n", "x", "o" }, "<A-Up>", function()
  local parser = vim.treesitter.get_parser(nil, nil, { error = false })
  if parser then
    require("vim.treesitter._select").select_parent(vim.v.count1)
  else
    vim.lsp.buf.selection_range(vim.v.count1)
  end
end, { desc = "Select parent treesitter node or outer incremental lsp selections" })

vim.keymap.set({ "n", "x", "o" }, "<A-Down>", function()
  local parser = vim.treesitter.get_parser(nil, nil, { error = false })
  if parser then
    require("vim.treesitter._select").select_child(vim.v.count1)
  else
    vim.lsp.buf.selection_range(-vim.v.count1)
  end
end, { desc = "Select child treesitter node or inner incremental lsp selections" })

-- Built-in undotree (Neovim 0.12+)
Config.later(function()
  vim.cmd.packadd("nvim.undotree")
  vim.keymap.set("n", "<leader>u", require("undotree").open, { desc = "Open undotree" })
end)
