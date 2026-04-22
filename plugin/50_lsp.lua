-- ============================================================================
-- LSP & Completion Configuration (plugin/50_lsp.lua)
-- ============================================================================

local add = vim.pack.add
local now_if_args = Config.now_if_args

-- ============================================================================
-- LSP Setup
-- ============================================================================

now_if_args(function()
  add({
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/williamboman/mason.nvim",
  })
  require("mason").setup({
    ui = {
      border = "rounded",
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗",
      },
    },
  })

  -- Use mini.completion for LSP capabilities
  local ok, _ = pcall(require, "mini.completion")
  local capabilities = ok and MiniCompletion.get_lsp_capabilities() or vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }

  vim.lsp.config("*", { capabilities = capabilities })
  vim.lsp.enable({ "ty", "gopls", "rust_analyzer", "jsonls", "yamlls", "protols", "lua_ls", "zls" })

  -- LSP global mappings
  vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic float", silent = true })
  vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Set diagnostic loclist", silent = true })

  -- LSP buffer local mappings
  Config.new_autocmd("LspAttach", "*", function(args)
    local bo = { buffer = args.buf, silent = true }
    vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", bo, { desc = "Show hover" }))
    vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, vim.tbl_extend("force", bo, { desc = "Rename" }))
    vim.keymap.set(
      "n",
      "<leader>k",
      vim.diagnostic.open_float,
      vim.tbl_extend("force", bo, { desc = "Show diagnostics" })
    )
    vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, vim.tbl_extend("force", bo, { desc = "Code actions" }))
    vim.keymap.set({ "n", "x" }, "<leader>i", function()
      vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } } })
    end, vim.tbl_extend("force", bo, { desc = "Organize imports" }))
  end, "LSP buffer local mappings")
end)

-- Organize imports command
vim.api.nvim_create_user_command("OR", function()
  vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } } })
end, { desc = "Organize imports" })
