-- ============================================================================
-- LSP Configuration (plugin/50_lsp.lua)
-- ============================================================================

local add = vim.pack.add
local now_if_args, later = Config.now_if_args, Config.later

now_if_args(function()
  add({ "https://github.com/neovim/nvim-lspconfig" })

  -- Wait for blink.cmp to be available for capabilities
  later(function()
    local ok, blink = pcall(require, "blink.cmp")
    local capabilities = ok and blink.get_lsp_capabilities() or vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    }

    vim.lsp.config("*", { capabilities = capabilities })

    -- Enable LSP servers
    vim.lsp.enable({ "ty", "gopls", "rust_analyzer", "jsonls", "yamlls", "protols", "lua_ls" })
  end)

  -- Disable default LSP keymaps
  local default_keymaps = { "grn", "gra", "grr", "gri", "grt", "grx" }
  for _, key in ipairs(default_keymaps) do
    pcall(vim.keymap.del, "n", key)
  end

  -- LSP global mappings
  vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic float", silent = true })
  vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Set diagnostic loclist", silent = true })

  -- LSP buffer local mappings
  Config.new_autocmd("LspAttach", "*", function(args)
    local opts = { buffer = args.buf }

    for _, key in ipairs(default_keymaps) do
      pcall(vim.keymap.del, "n", key, { buffer = args.buf })
    end

    vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Show hover", silent = true }))
    vim.keymap.set(
      "n",
      "<leader>r",
      vim.lsp.buf.rename,
      vim.tbl_extend("force", opts, { desc = "Rename", silent = true })
    )
    vim.keymap.set(
      "n",
      "<leader>k",
      vim.diagnostic.open_float,
      vim.tbl_extend("force", opts, { desc = "Show diagnostics", silent = true })
    )
    vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, { silent = true, desc = "Code actions" })
  end, "LSP buffer local mappings")
end)

-- ============================================================================
-- Organize imports command
-- ============================================================================

vim.api.nvim_create_user_command("OR", function()
  vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } } })
end, {})
