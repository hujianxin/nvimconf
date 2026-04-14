-- ============================================================================
-- Testing Configuration (plugin/90_test.lua)
-- ============================================================================
--
-- Neotest setup with language-specific adapters.
-- Adapters are loaded on-demand when their respective filetypes are opened.

local add = vim.pack.add
local on_filetype = Config.on_filetype

-- Store adapters to be registered
local pending_adapters = {}

-- ============================================================================
-- Helper to register adapters
-- ============================================================================

local function register_adapter(name, factory)
  -- If neotest is already loaded, register immediately
  local ok, neotest = pcall(require, "neotest")
  if ok and neotest then
    local adapter = factory()
    if adapter then
      -- Get current adapters
      local adapters = {}
      if neotest._adapters then
        for _, a in pairs(neotest._adapters) do
          table.insert(adapters, a)
        end
      end
      table.insert(adapters, adapter)
      neotest.setup({ adapters = adapters })
    end
  else
    -- Store for later registration
    pending_adapters[name] = factory
  end
end

-- ============================================================================
-- Neotest - Test framework (lazy-loaded on command)
-- ============================================================================

local neotest_loaded = false
local function ensure_neotest()
  if neotest_loaded then
    return
  end
  neotest_loaded = true
  add({
    "https://github.com/nvim-neotest/neotest",
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/nvim-treesitter/nvim-treesitter",
    "https://github.com/antoinemadec/FixCursorHold.nvim",
    "https://github.com/nvim-neotest/nvim-nio",
    "https://github.com/stevearc/overseer.nvim",
  })

  -- Setup neotest
  local adapters = {}
  for _, factory in pairs(pending_adapters) do
    local ok, adapter = pcall(factory)
    if ok and adapter then
      table.insert(adapters, adapter)
    end
  end
  pending_adapters = {}

  require("neotest").setup({
    consumers = { overseer = require("neotest.consumers.overseer") },
    overseer = { enabled = true, force_default = true },
    adapters = adapters,
    discovery = { enabled = true, concurrent = 8 },
    running = { concurrent = true },
    summary = { enabled = true, follow = true, open = "botright split | resize 20" },
    status = { enabled = true, virtual_text = true },
    output = { enabled = true, open_on_run = "short" },
    icons = { passed = "", failed = "", running = "", skipped = "", unknown = "?" },
  })

  -- Close keymaps for neotest-output
  Config.new_autocmd("FileType", "neotest-output", function(args)
    vim.keymap.set("n", "q", function()
      vim.api.nvim_win_close(0, true)
    end, { buffer = args.buf, silent = true })
    vim.keymap.set("n", "<Esc>", function()
      vim.api.nvim_win_close(0, true)
    end, { buffer = args.buf, silent = true })
  end, "Close keymaps for neotest-output")
end

-- Keymaps (trigger lazy loading)
vim.keymap.set("n", "<leader>Tt", function()
  ensure_neotest()
  require("neotest").run.run()
end, { desc = "Run nearest test" })
vim.keymap.set("n", "<leader>Tf", function()
  ensure_neotest()
  require("neotest").run.run(vim.fn.expand("%"))
end, { desc = "Run all tests in file" })
vim.keymap.set("n", "<leader>Ts", function()
  ensure_neotest()
  require("neotest").run.stop()
end, { desc = "Stop test" })
vim.keymap.set("n", "<leader>Ta", function()
  ensure_neotest()
  require("neotest").run.attach()
end, { desc = "Attach to running test" })
vim.keymap.set("n", "<leader>TO", function()
  ensure_neotest()
  require("neotest").output.open({ enter = true })
end, { desc = "Show test output" })
vim.keymap.set("n", "<leader>To", function()
  ensure_neotest()
  require("neotest").output_panel.toggle()
end, { desc = "Toggle test output panel" })
vim.keymap.set("n", "<leader>TS", function()
  ensure_neotest()
  require("neotest").summary.toggle()
end, { desc = "Toggle test summary" })

-- ============================================================================
-- Neotest adapters - Register on filetype (loaded when neotest initializes)
-- ============================================================================

-- Rust
on_filetype("rust", function()
  -- Just mark that we need rust adapter; actual loading happens in neotest setup
  pending_adapters["rust"] = function()
    -- Ensure dependencies are loaded
    add({
      "https://github.com/nvim-lua/plenary.nvim",
      "https://github.com/mrcjkb/rustaceanvim",
    })
    return require("rustaceanvim.neotest")
  end
  -- Trigger neotest load if not already loaded
  local ok, _ = pcall(require, "neotest")
  if ok then
    register_adapter("rust", pending_adapters["rust"])
  end
end)

-- Zig
on_filetype("zig", function()
  pending_adapters["zig"] = function()
    add({
      "https://github.com/nvim-lua/plenary.nvim",
      "https://github.com/StephanMoeller/neotest-zig",
    })
    return require("neotest-zig")()
  end
  local ok, _ = pcall(require, "neotest")
  if ok then
    register_adapter("zig", pending_adapters["zig"])
  end
end)

-- Go
on_filetype("go", function()
  pending_adapters["go"] = function()
    add({
      "https://github.com/nvim-lua/plenary.nvim",
      "https://github.com/nvim-neotest/neotest-go",
    })
    return require("neotest-go")
  end
  local ok, _ = pcall(require, "neotest")
  if ok then
    register_adapter("go", pending_adapters["go"])
  end
end)

-- Python
on_filetype("python", function()
  pending_adapters["python"] = function()
    add({
      "https://github.com/nvim-lua/plenary.nvim",
      "https://github.com/nvim-neotest/neotest-python",
    })
    return require("neotest-python")({
      args = { "--log-level", "DEBUG" },
      runner = "pytest",
      python = ".venv/bin/python",
      pytest_discover_instances = true,
    })
  end
  local ok, _ = pcall(require, "neotest")
  if ok then
    register_adapter("python", pending_adapters["python"])
  end
end)
