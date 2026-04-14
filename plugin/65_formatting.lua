-- ============================================================================
-- Formatting Configuration (plugin/65_formatting.lua)
-- ============================================================================

local add = vim.pack.add
local later = Config.later

later(function()
  add({ "https://github.com/stevearc/conform.nvim" })

  require("conform").setup({
    default_format_opts = { lsp_format = "fallback" },
    formatters_by_ft = {
      cpp = { "clang-format" },
      c = { "clang-format" },
      proto = { "clang-format" },
      lua = { "stylua" },
      go = { "goimports", "gofmt" },
      rust = { "rustfmt", lsp_format = "fallback" },
      python = function(bufnr)
        if require("conform").get_formatter_info("ruff_format", bufnr).available then
          return { "ruff_format" }
        else
          return { "isort", "black" }
        end
      end,
      javascript = { "prettierd", "prettier", stop_after_first = true },
      bzl = { "buildifier" },
      zig = { "zigfmt" },
      cmake = { "gersemi" },
    },
  })

  vim.keymap.set("n", "=", function()
    require("conform").format({ async = true, lsp_fallback = true })
  end, { desc = "Format code" })

  vim.api.nvim_create_user_command("Format", function()
    require("conform").format({ async = true, lsp_fallback = true })
  end, {})
end)
