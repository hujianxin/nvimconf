-- ============================================================================
-- Formatting Configuration (plugin/60_formatting.lua)
-- ============================================================================

local add = vim.pack.add

local function fmt()
  if not package.loaded['conform'] then
    add({ 'https://github.com/stevearc/conform.nvim' })
    require('conform').setup({
      default_format_opts = { lsp_format = 'fallback' },
      formatters_by_ft = {
        cpp = { 'clang-format' },
        c = { 'clang-format' },
        proto = { 'clang-format' },
        lua = { 'stylua' },
        go = { 'goimports', 'gofmt' },
        rust = { 'rustfmt', lsp_format = 'fallback' },
        python = function(bufnr)
          if require('conform').get_formatter_info('ruff_format', bufnr).available then
            return { 'ruff_format' }
          end
          return { 'isort', 'black' }
        end,
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        bzl = { 'buildifier' },
        zig = { 'zigfmt' },
        cmake = { 'gersemi' },
      },
    })
  end
  require('conform').format({ async = true, lsp_format = 'fallback' })
end

vim.keymap.set('n', '=', fmt, { desc = 'Format code' })
vim.api.nvim_create_user_command('Format', fmt, { desc = 'Format code' })
