-- ============================================================================
-- Lua Language Server Configuration (after/lsp/lua_ls.lua)
-- ============================================================================
--
-- This file configures the lua-language-server (lua_ls) for Neovim Lua development.
-- It is used by vim.lsp.enable() and vim.lsp.config().
-- See :h vim.lsp.Config for available fields.

return {
  on_attach = function(client, buf_id)
    -- Optimize completion triggers for better experience
    client.server_capabilities.completionProvider.triggerCharacters = { ".", ":", "#" }

    -- You can add buffer-local LSP mappings here if needed
    -- vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = buf_id })
  end,
  settings = {
    Lua = {
      runtime = {
        -- Use LuaJIT as it's built into Neovim
        version = "LuaJIT",
        path = vim.split(package.path, ";"),
      },
      workspace = {
        -- Don't analyze code from submodules
        ignoreSubmodules = true,
        -- Add Neovim runtime for better completion
        library = { vim.env.VIMRUNTIME },
        -- Avoid prompts about third-party libraries
        checkThirdParty = false,
      },
      telemetry = {
        -- Disable telemetry
        enable = false,
      },
    },
  },
}
