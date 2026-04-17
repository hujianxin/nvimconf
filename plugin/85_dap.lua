-- ============================================================================
-- DAP Configuration (plugin/85_dap.lua)
-- ============================================================================
--
-- Debug Adapter Protocol setup with nvim-dap-view.
-- Fully lazy-loaded: nothing loads until a DAP keymap or command is triggered.
--
-- Uses `<leader>D` prefix.

local add = vim.pack.add

-- ============================================================================
-- DAP + dap-view (lazy-loaded on command/keymap)
-- ============================================================================

local dap_loaded = false
local function ensure_dap()
  if dap_loaded then
    return
  end
  dap_loaded = true
  add({
    "https://github.com/mfussenegger/nvim-dap",
    "https://github.com/igorlfs/nvim-dap-view",
    "https://github.com/nvim-neotest/nvim-nio",
  })

  local dap = require("dap")
  local dapview = require("dap-view")

  dapview.setup({
    winbar = {
      controls = {
        enabled = true,
      },
    },
  })

  -- Auto open/close dap-view with debug sessions
  dap.listeners.after.event_initialized["dap-view"] = function()
    dapview.open()
  end
  dap.listeners.after.event_terminated["dap-view"] = function()
    dapview.close()
  end
  dap.listeners.after.event_exited["dap-view"] = function()
    dapview.close()
  end

  -- Breakpoint signs
  vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint" })
  vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DapBreakpointCondition" })
  vim.fn.sign_define("DapBreakpointRejected", { text = "✗", texthl = "DapBreakpointRejected" })
  vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPoint" })
  vim.fn.sign_define("DapStopped", { text = "→", texthl = "DapStopped", linehl = "DapStoppedLine" })

  -- Go (delve)
  dap.adapters.delve = {
    type = "server",
    port = "${port}",
    executable = {
      command = "dlv",
      args = { "dap", "-l", "127.0.0.1:${port}" },
    },
  }
  dap.configurations.go = {
    { name = "Debug", type = "delve", request = "launch", program = "${file}" },
    { name = "Debug test", type = "delve", request = "launch", mode = "test", program = "${file}" },
  }

  -- Rust/Zig/C/C++ (codelldb)
  dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
      command = "codelldb",
      args = { "--port", "${port}" },
    },
  }
  for _, ft in ipairs({ "rust", "zig", "c", "cpp" }) do
    dap.configurations[ft] = {
      {
        name = "Debug",
        type = "codelldb",
        request = "launch",
        program = function()
          return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
      },
    }
  end
end

-- Keymaps (trigger lazy loading)
vim.keymap.set("n", "<leader>Db", function()
  ensure_dap()
  require("dap").toggle_breakpoint()
end, { desc = "Toggle breakpoint" })
vim.keymap.set("n", "<leader>DB", function()
  ensure_dap()
  require("dap").set_breakpoint(vim.fn.input("Condition: "))
end, { desc = "Conditional breakpoint" })
vim.keymap.set("n", "<leader>Dc", function()
  ensure_dap()
  require("dap").continue()
end, { desc = "Continue/start" })
vim.keymap.set("n", "<leader>DC", function()
  ensure_dap()
  require("dap").run_to_cursor()
end, { desc = "Run to cursor" })
vim.keymap.set("n", "<leader>Ds", function()
  ensure_dap()
  require("dap").step_over()
end, { desc = "Step over" })
vim.keymap.set("n", "<leader>Di", function()
  ensure_dap()
  require("dap").step_into()
end, { desc = "Step into" })
vim.keymap.set("n", "<leader>Do", function()
  ensure_dap()
  require("dap").step_out()
end, { desc = "Step out" })
vim.keymap.set("n", "<leader>Dp", function()
  ensure_dap()
  require("dap").terminate()
  require("dap").repl.close()
  require("dap-view").close()
end, { desc = "Stop debugging" })
vim.keymap.set("n", "<leader>Dv", function()
  ensure_dap()
  require("dap-view").toggle()
end, { desc = "Toggle DAP view" })
vim.keymap.set("n", "<leader>Dr", function()
  ensure_dap()
  require("dap").repl.open()
end, { desc = "REPL" })
vim.keymap.set("n", "<leader>De", function()
  ensure_dap()
  require("dap.ui.widgets").hover()
end, { desc = "Evaluate" })

-- User commands (trigger lazy loading)
vim.api.nvim_create_user_command("Debug", function()
  ensure_dap()
  require("dap").continue()
end, { desc = "Start debug session" })
vim.api.nvim_create_user_command("Breakpoint", function()
  ensure_dap()
  require("dap").toggle_breakpoint()
end, { desc = "Toggle breakpoint" })
vim.api.nvim_create_user_command("DapView", function()
  ensure_dap()
  require("dap-view").toggle()
end, { desc = "Toggle DAP view" })
