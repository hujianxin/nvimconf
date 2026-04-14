-- ============================================================================
-- Completion Configuration (plugin/60_completion.lua)
-- ============================================================================

local add = vim.pack.add
local on_event = Config.on_event

-- ============================================================================
-- Helper to check if blink.cmp Rust library exists
-- ============================================================================

local function blink_cmp_lib_exists()
  local pack_path = vim.fs.joinpath(vim.fn.stdpath("data"), "site/pack/core/opt/blink.cmp")
  local lib_ext = vim.fn.has("win32") == 1 and ".dll" or (vim.fn.has("mac") == 1 and ".dylib" or ".so")
  local lib_path = vim.fs.joinpath(pack_path, "target/release/libblink_cmp_fuzzy" .. lib_ext)
  return vim.uv.fs_stat(lib_path) ~= nil
end

-- ============================================================================
-- Async build blink.cmp from source
-- ============================================================================

local function build_blink_cmp_async()
  if vim.fn.executable("cargo") == 0 then
    vim.notify(
      "blink.cmp: Rust not found. Using Lua implementation.\nInstall Rust for better performance: https://rustup.rs/",
      vim.log.levels.WARN
    )
    return false
  end

  local pack_path = vim.fs.joinpath(vim.fn.stdpath("data"), "site/pack/core/opt/blink.cmp")
  local lib_ext = vim.fn.has("win32") == 1 and ".dll" or (vim.fn.has("mac") == 1 and ".dylib" or ".so")
  local lib_path = vim.fs.joinpath(pack_path, "target/release/libblink_cmp_fuzzy" .. lib_ext)

  -- Check if already exists
  if vim.uv.fs_stat(lib_path) then
    return true
  end

  vim.notify("blink.cmp: Building Rust fuzzy matcher in background...", vim.log.levels.INFO)

  -- Build asynchronously using vim.system (Neovim 0.10+)
  vim.system({
    "cargo",
    "build",
    "--release",
    "--manifest-path",
    vim.fs.joinpath(pack_path, "Cargo.toml"),
  }, {
    cwd = pack_path,
  }, function(obj)
    vim.schedule(function()
      if obj.code == 0 then
        vim.notify("blink.cmp: Rust fuzzy matcher built successfully! Restart Neovim to use it.", vim.log.levels.INFO)
      else
        vim.notify("blink.cmp: Build failed. Using Lua implementation.\n" .. (obj.stderr or ""), vim.log.levels.WARN)
      end
    end)
  end)

  -- Return false for now (will use Lua until next restart)
  return false
end

-- ============================================================================
-- blink.cmp - Load with async auto-compilation
-- ============================================================================

on_event("InsertEnter", function()
  add({
    "https://github.com/saghen/blink.cmp",
    "https://github.com/rafamadriz/friendly-snippets",
  })

  -- Check if library exists, if not start async build
  local has_rust_lib = blink_cmp_lib_exists()

  -- If no library and cargo available, start async build for next time
  if not has_rust_lib and vim.fn.executable("cargo") == 1 then
    build_blink_cmp_async()
  end

  require("blink.cmp").setup({
    keymap = {
      preset = "default",
      ["<CR>"] = { "accept", "fallback" },
      ["<Tab>"] = { "accept", "fallback" },
    },
    appearance = { nerd_font_variant = "mono" },
    signature = { enabled = true },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
      providers = {
        snippets = {
          opts = {
            search_paths = { vim.fn.stdpath("config") .. "/snippets" },
          },
        },
      },
    },
    -- Use Rust if available, otherwise Lua
    fuzzy = {
      implementation = has_rust_lib and "prefer_rust_with_warning" or "lua",
    },
  })
end)
