-- ============================================================================
-- DAP Configuration (plugin/85_dap.lua)
-- ============================================================================
-- Debug Adapter Protocol setup with nvim-dap-view.
-- Fully lazy-loaded: nothing loads until a DAP keymap or command is triggered.
-- Uses `<leader>D` prefix.

local add = vim.pack.add

local function ensure_dap()
  if package.loaded["dap"] then
    return
  end
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

for _, spec in ipairs({
  {
    "<leader>Db",
    function()
      require("dap").toggle_breakpoint()
    end,
    "Toggle breakpoint",
  },
  {
    "<leader>DB",
    function()
      require("dap").set_breakpoint(vim.fn.input("Condition: "))
    end,
    "Conditional breakpoint",
  },
  {
    "<leader>Dc",
    function()
      require("dap").continue()
    end,
    "Continue/start",
  },
  {
    "<leader>DC",
    function()
      require("dap").run_to_cursor()
    end,
    "Run to cursor",
  },
  {
    "<leader>Ds",
    function()
      require("dap").step_over()
    end,
    "Step over",
  },
  {
    "<leader>Di",
    function()
      require("dap").step_into()
    end,
    "Step into",
  },
  {
    "<leader>Do",
    function()
      require("dap").step_out()
    end,
    "Step out",
  },
  {
    "<leader>Dr",
    function()
      require("dap").repl.open()
    end,
    "REPL",
  },
  {
    "<leader>De",
    function()
      require("dap.ui.widgets").hover()
    end,
    "Evaluate",
  },
  {
    "<leader>Dp",
    function()
      require("dap").terminate()
      require("dap").repl.close()
      require("dap-view").close()
    end,
    "Stop debugging",
  },
  {
    "<leader>Dv",
    function()
      require("dap-view").toggle()
    end,
    "Toggle DAP view",
  },
}) do
  vim.keymap.set("n", spec[1], function()
    ensure_dap()
    spec[2]()
  end, { desc = spec[3] })
end

for _, spec in ipairs({
  {
    "Debug",
    function()
      require("dap").continue()
    end,
    "Start debug session",
  },
  {
    "Breakpoint",
    function()
      require("dap").toggle_breakpoint()
    end,
    "Toggle breakpoint",
  },
  {
    "DapView",
    function()
      require("dap-view").toggle()
    end,
    "Toggle DAP view",
  },
}) do
  vim.api.nvim_create_user_command(spec[1], function()
    ensure_dap()
    spec[2]()
  end, { desc = spec[3] })
end
