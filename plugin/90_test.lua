-- ============================================================================
-- Test Configuration (plugin/90_test.lua)
-- ============================================================================

local add = vim.pack.add

local test_loaded = false
local function ensure_test()
  if test_loaded then
    return
  end
  test_loaded = true
  add({ "https://github.com/vim-test/vim-test" })
  vim.g["test#strategy"] = "neovim_sticky"
end

vim.api.nvim_create_user_command("TestNearest", function()
  ensure_test()
  vim.cmd("TestNearest")
end, { desc = "Run nearest test" })

vim.api.nvim_create_user_command("TestFile", function()
  ensure_test()
  vim.cmd("TestFile")
end, { desc = "Run test file" })

vim.api.nvim_create_user_command("TestSuite", function()
  ensure_test()
  vim.cmd("TestSuite")
end, { desc = "Run test suite" })

vim.api.nvim_create_user_command("TestLast", function()
  ensure_test()
  vim.cmd("TestLast")
end, { desc = "Run last test" })

vim.api.nvim_create_user_command("TestVisit", function()
  ensure_test()
  vim.cmd("TestVisit")
end, { desc = "Visit last test" })

vim.keymap.set("n", "<leader>tn", ":TestNearest<CR>", { desc = "Test nearest" })
vim.keymap.set("n", "<leader>tt", ":TestNearest<CR>", { desc = "Test nearest" })
vim.keymap.set("n", "<leader>tf", ":TestFile<CR>", { desc = "Test file" })
vim.keymap.set("n", "<leader>ts", ":TestSuite<CR>", { desc = "Test suite" })
vim.keymap.set("n", "<leader>tl", ":TestLast<CR>", { desc = "Test last" })
vim.keymap.set("n", "<leader>tv", ":TestVisit<CR>", { desc = "Test visit" })
