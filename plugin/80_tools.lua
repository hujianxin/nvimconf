-- ============================================================================
-- Tools Configuration (plugin/80_tools.lua)
-- ============================================================================

local add = vim.pack.add
local later, on_event, on_filetype = Config.later, Config.on_event, Config.on_filetype

-- ============================================================================
-- Overseer - Task runner
-- ============================================================================

later(function()
  add({ "https://github.com/stevearc/overseer.nvim" })

  require("overseer").setup({
    log_level = vim.log.levels.TRACE,
    component_aliases = {
      default = {
        "on_exit_set_status",
        { "on_complete_notify", system = "unfocused" },
        { "on_complete_dispose", require_view = { "SUCCESS", "FAILURE" } },
      },
      default_neotest = {
        "unique",
        { "on_complete_notify", system = "unfocused", on_change = true },
        "default",
      },
    },
  })

  -- Commands
  vim.cmd.cnoreabbrev("OS OverseerShell")

  -- Keymaps
  vim.keymap.set("n", "<leader>Ot", "<cmd>OverseerToggle!<CR>", { desc = "Toggle" })
  vim.keymap.set("n", "<leader>Or", "<cmd>OverseerRun<CR>", { desc = "Run" })
  vim.keymap.set("n", "<leader>Os", "<cmd>OverseerShell<CR>", { desc = "Shell" })
  vim.keymap.set("n", "<leader>OT", "<cmd>OverseerTaskAction<CR>", { desc = "Task action" })
  vim.keymap.set("n", "<leader>Od", function()
    local overseer = require("overseer")
    local tasks =
      overseer.list_tasks({ sort = require("overseer.task_list").sort_finished_recently, include_ephemeral = true })
    if vim.tbl_isempty(tasks) then
      vim.notify("No tasks found", vim.log.levels.WARN)
    else
      overseer.run_action(tasks[1])
    end
  end, { desc = "Do quick action" })

  -- User commands
  vim.api.nvim_create_user_command("OverseerTestOutput", function()
    vim.cmd.tabnew()
    vim.bo.bufhidden = "wipe"
    require("overseer").create_task_output_view(0, {
      select = function(self, tasks)
        for _, task in ipairs(tasks) do
          if task.metadata.neotest_group_id then
            return task
          end
        end
        self:dispose()
      end,
    })
  end, { desc = "Open a new tab that displays the output of the most recent test" })

  vim.api.nvim_create_user_command("Make", function(params)
    local cmd, num_subs = vim.o.makeprg:gsub("%$%*", params.args)
    if num_subs == 0 then
      cmd = cmd .. " " .. params.args
    end
    local task = require("overseer").new_task({
      cmd = vim.fn.expandcmd(cmd),
      components = {
        { "on_output_quickfix", open = not params.bang, open_height = 8 },
        "unique",
        "default",
      },
    })
    task:start()
  end, { desc = "Run your makeprg as an Overseer task", nargs = "*", bang = true })
end)

-- ============================================================================
-- Multicursor
-- ============================================================================

later(function()
  add({ "https://github.com/jake-stewart/multicursor.nvim" })

  local mc = require("multicursor-nvim")
  mc.setup()

  local set = vim.keymap.set
  set({ "n", "x" }, "<C-up>", function()
    mc.lineAddCursor(-1)
  end)
  set({ "n", "x" }, "<C-down>", function()
    mc.lineAddCursor(1)
  end)
  set({ "n", "x" }, "<leader><up>", function()
    mc.lineSkipCursor(-1)
  end)
  set({ "n", "x" }, "<leader><down>", function()
    mc.lineSkipCursor(1)
  end)
  set({ "n", "x" }, "<leader>A", mc.matchAllAddCursors)
  set({ "n", "x" }, "<C-n>", function()
    mc.matchAddCursor(1)
  end)
  set({ "n", "x" }, "<C-s>", function()
    mc.matchSkipCursor(1)
  end)
  set({ "n", "x" }, "<C-S-n>", function()
    mc.matchAddCursor(-1)
  end)
  set({ "n", "x" }, "<C-S-s>", function()
    mc.matchSkipCursor(-1)
  end)
  set("n", "<c-leftmouse>", mc.handleMouse)
  set("n", "<c-leftdrag>", mc.handleMouseDrag)
  set("n", "<c-leftrelease>", mc.handleMouseRelease)
  set({ "n", "x" }, "<c-q>", mc.toggleCursor)

  mc.addKeymapLayer(function(layerSet)
    layerSet({ "n", "x" }, "<left>", mc.prevCursor)
    layerSet({ "n", "x" }, "<right>", mc.nextCursor)
    layerSet({ "n", "x" }, "<M-x>", mc.deleteCursor)
    layerSet("n", "<esc>", function()
      if not mc.cursorsEnabled() then
        mc.enableCursors()
      else
        mc.clearCursors()
      end
    end)
  end)

  -- Highlights
  local hl = vim.api.nvim_set_hl
  hl(0, "MultiCursorCursor", { reverse = true })
  hl(0, "MultiCursorVisual", { link = "Visual" })
  hl(0, "MultiCursorSign", { link = "SignColumn" })
  hl(0, "MultiCursorMatchPreview", { link = "Search" })
  hl(0, "MultiCursorDisabledCursor", { reverse = true })
  hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
  hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
end)

-- ============================================================================
-- ToggleTerm - Terminal
-- ============================================================================

-- ToggleTerm keymaps (defined globally)
later(function()
  -- Store last used terminal number (1 by default)
  local last_term_num = 1

  -- Helper to ensure toggleterm is loaded
  local ensure_toggleterm = function()
    if not package.loaded["toggleterm"] then
      add({ "https://github.com/akinsho/toggleterm.nvim" })
      require("toggleterm").setup({
        size = 20,
        hide_numbers = true,
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        terminal_mappings = true,
        persist_size = true,
        persist_mode = true,
        direction = "float",
        close_on_exit = true,
        shell = vim.o.shell,
        auto_scroll = true,
        float_opts = { border = "curved", winblend = 0 },
      })
    end
  end

  vim.keymap.set({ "n", "i", "t" }, "<d-j>", function()
    ensure_toggleterm()
    local count = vim.v.count1
    local target_term
    if vim.v.count > 0 then
      -- If count provided, use it and remember as last used
      target_term = count
      last_term_num = target_term
    else
      -- No count: toggle the last used terminal
      target_term = last_term_num
    end
    vim.cmd.execute("'" .. target_term .. "ToggleTerm direction=horizontal'")
  end, { desc = "Toggle terminal" })

  -- Exit terminal mode
  vim.keymap.set("t", "<esc><esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
end)

-- ============================================================================
-- Auto-save
-- ============================================================================

on_event({ "InsertLeave", "TextChanged" }, function()
  if package.loaded["auto-save"] then
    return
  end

  add({ "https://github.com/okuuva/auto-save.nvim" })
  require("auto-save").setup()
end)

-- ============================================================================
-- LazyGit
-- ============================================================================

later(function()
  add({
    "https://github.com/kdheepak/lazygit.nvim",
    "https://github.com/nvim-lua/plenary.nvim",
  })
  vim.keymap.set("n", "<c-g>", "<cmd>LazyGit<cr>", { desc = "LazyGit" })
end)

-- ============================================================================
-- Compile Mode
-- ============================================================================

later(function()
  add({
    "https://github.com/ej-shafran/compile-mode.nvim",
    "https://github.com/nvim-lua/plenary.nvim",
  })

  vim.g.compile_mode = {
    input_word_completion = true,
    baleia_setup = true,
    bang_expansion = true,
  }

  vim.keymap.set("n", "<leader>Cc", "<cmd>Compile<CR>", { desc = "Compile" })
  vim.keymap.set("n", "<leader>Cr", "<cmd>Recompile<CR>", { desc = "Recompile" })
end)

-- ============================================================================
-- Kulala (HTTP client)
-- ============================================================================

on_filetype({ "http", "rest" }, function()
  add({ "https://github.com/mistweaverco/kulala.nvim" })
  require("kulala").setup({
    global_keymaps = true,
    global_keymaps_prefix = "<leader>K",
    kulala_keymaps_prefix = "",
  })
end)
