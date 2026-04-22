-- ============================================================================
-- DAP Configuration (plugin/85_dap.lua)
-- ============================================================================
-- Debug Adapter Protocol setup with nvim-dap-view.
-- Fully lazy-loaded: nothing loads until a DAP keymap or command is triggered.
-- Uses `<leader>D` prefix.

local add = vim.pack.add

local function dap_fn(fn, ...)
  if not package.loaded["dap"] then
    add({
      "https://github.com/mfussenegger/nvim-dap",
      "https://github.com/igorlfs/nvim-dap-view",
      "https://github.com/nvim-neotest/nvim-nio",
    })

    local dap = require("dap")
    local dapview = require("dap-view")
    dapview.setup({ winbar = { controls = { enabled = true } } })

    dap.listeners.after.event_initialized["dap-view"] = function()
      dapview.open()
    end
    dap.listeners.after.event_terminated["dap-view"] = function()
      dapview.close()
    end
    dap.listeners.after.event_exited["dap-view"] = function()
      dapview.close()
    end

    for _, spec in ipairs({
      { "DapBreakpoint", "●" },
      { "DapBreakpointCondition", "◆" },
      { "DapBreakpointRejected", "✗" },
      { "DapLogPoint", "◆" },
      { "DapStopped", "→", "DapStoppedLine" },
    }) do
      local opts = { text = spec[2], texthl = spec[1] }
      if spec[3] then
        opts.linehl = spec[3]
      end
      vim.fn.sign_define(spec[1], opts)
    end

    dap.adapters.delve = {
      type = "server",
      port = "${port}",
      executable = { command = "dlv", args = { "dap", "-l", "127.0.0.1:${port}" } },
    }
    dap.configurations.go = {
      { name = "Debug", type = "delve", request = "launch", program = "${file}" },
      { name = "Debug test", type = "delve", request = "launch", mode = "test", program = "${file}" },
    }

    dap.adapters.codelldb = {
      type = "server",
      port = "${port}",
      executable = { command = "codelldb", args = { "--port", "${port}" } },
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
  return function()
    require("dap")[fn](...)
  end
end

for _, spec in ipairs({
  { "<leader>Db", "toggle_breakpoint", "Toggle breakpoint" },
  { "<leader>DB", "set_breakpoint", "Conditional breakpoint", vim.fn.input("Condition: ") },
  { "<leader>Dc", "continue", "Continue/start" },
  { "<leader>DC", "run_to_cursor", "Run to cursor" },
  { "<leader>Ds", "step_over", "Step over" },
  { "<leader>Di", "step_into", "Step into" },
  { "<leader>Do", "step_out", "Step out" },
  { "<leader>Dr", "repl.open", "REPL" },
  {
    "<leader>De",
    function()
      require("dap.ui.widgets").hover()
    end,
    "Evaluate",
  },
}) do
  if type(spec[2]) == "function" then
    vim.keymap.set(
      "n",
      spec[1],
      dap_fn(function()
        spec[2]()
      end),
      { desc = spec[3] }
    )
  else
    vim.keymap.set("n", spec[1], dap_fn(spec[2], spec[4]), { desc = spec[3] })
  end
end

vim.keymap.set(
  "n",
  "<leader>Dp",
  dap_fn(function()
    require("dap").terminate()
    require("dap").repl.close()
    require("dap-view").close()
  end),
  { desc = "Stop debugging" }
)

vim.keymap.set(
  "n",
  "<leader>Dv",
  dap_fn(function()
    require("dap-view").toggle()
  end),
  { desc = "Toggle DAP view" }
)

for _, spec in ipairs({
  { "Debug", "continue", "Start debug session" },
  { "Breakpoint", "toggle_breakpoint", "Toggle breakpoint" },
  {
    "DapView",
    function()
      require("dap-view").toggle()
    end,
    "Toggle DAP view",
  },
}) do
  vim.api.nvim_create_user_command(spec[1], dap_fn(spec[2]), { desc = spec[3] })
end
