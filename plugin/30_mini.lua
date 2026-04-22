-- ============================================================================
-- Mini.nvim Configuration (plugin/30_mini.lua)
-- ============================================================================
-- All mini plugins organized with MiniMax staged loading strategy

local add = vim.pack.add
local now, now_if_args, later = Config.now, Config.now_if_args, Config.later

-- ============================================================================
-- Step One (now) - Immediately loaded for first screen rendering
-- ============================================================================

-- mini.basics - Common configuration presets
now(function()
  require("mini.basics").setup({
    options = {
      basic = false,
      extra_ui = false,
      win_borders = "single",
    },
    mappings = {
      basic = true,
      option_toggle_prefix = [[\]],
      windows = false,
      move_with_alt = false,
    },
    autocommands = {
      basic = true,
      relnum_in_visual_mode = false,
    },
    silent = true,
  })
end)

-- Set colorscheme from mini.nvim
now(function()
  vim.cmd.colorscheme("miniwinter")
end)

-- mini.icons - Icon provider
now(function()
  require("mini.icons").setup({
    style = "glyph",
  })
  MiniIcons = require("mini.icons")
  -- Mock nvim-web-devicons for compatibility
  package.preload["nvim-web-devicons"] = function()
    require("mini.icons").mock_nvim_web_devicons()
    return package.loaded["nvim-web-devicons"]
  end
  -- Add LSP kind icons for mini.completion
  later(MiniIcons.tweak_lsp_kind)
end)

-- mini.notify - Notification manager
now(function()
  require("mini.notify").setup({
    window = {
      config = { border = "rounded" },
      winblend = 0,
    },
  })
  vim.notify = MiniNotify.make_notify()
  vim.keymap.set("n", "<leader>Tn", "<cmd>lua MiniNotify.show_history()<cr>", { desc = "Show notification history" })
end)

-- mini.sessions - Session management
now(function()
  require("mini.sessions").setup({
    -- Directory where sessions are stored (default: vim.fn.stdpath('data') .. '/session')
    directory = vim.fn.stdpath("data") .. "/sessions",
    -- Whether to force possibly harmful actions (meaning depends on function)
    force = { read = false, write = true, delete = false },
    -- Hook functions for actions (nil means no hook)
    hooks = {
      -- Before successful action
      pre = { read = nil, write = nil, delete = nil },
      -- After successful action
      post = {
        read = function()
          vim.notify("Session loaded", vim.log.levels.INFO)
        end,
        write = function()
          vim.notify("Session saved", vim.log.levels.INFO)
        end,
        delete = nil,
      },
    },
    -- Whether to print session path after action
    verbose = { read = false, write = true, delete = true },
  })
  -- Session management keymaps
  vim.keymap.set("n", "<leader>Ss", "<cmd>lua MiniSessions.select('read')<cr>", { desc = "Select and load session" })
  vim.keymap.set(
    "n",
    "<leader>Sd",
    "<cmd>lua MiniSessions.select('delete')<cr>",
    { desc = "Select and delete session" }
  )
  vim.keymap.set("n", "<leader>Sw", "<cmd>lua MiniSessions.write()<cr>", { desc = "Write current session" })
  vim.keymap.set("n", "<leader>Sr", "<cmd>lua MiniSessions.read()<cr>", { desc = "Read last session" })

  -- Auto-save session before exiting Neovim
  Config.new_autocmd("VimLeavePre", "*", function()
    -- Only save if there are valid buffers (not just empty/nofile buffers)
    local has_valid_buffer = false
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(bufnr) then
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        local buftype = vim.bo[bufnr].buftype
        if bufname ~= "" and buftype ~= "nofile" and buftype ~= "quickfix" and buftype ~= "help" then
          has_valid_buffer = true
          break
        end
      end
    end
    if has_valid_buffer then
      MiniSessions.write("auto", { force = true })
    end
  end, "Auto-save session before exit")
end)

-- mini.statusline - Statusline
now(function()
  local MiniStatusline = require("mini.statusline")

  -- Patch section_mode to return 3-letter uppercase mode
  local orig_section_mode = MiniStatusline.section_mode
  MiniStatusline.section_mode = function(args)
    local mode, mode_hl = orig_section_mode(args)
    local mode_map = {
      Normal = "NOR",
      Insert = "INS",
      Visual = "VIS",
      ["V-Line"] = "V-L",
      ["V-Block"] = "V-B",
      Select = "SEL",
      ["S-Line"] = "S-L",
      ["S-Block"] = "S-B",
      Replace = "REP",
      Command = "CMD",
      Prompt = "PRM",
      Shell = "SHL",
      Terminal = "TRM",
      Unknown = "UNK",
    }
    return mode_map[mode] or mode:sub(1, 3):upper(), mode_hl
  end

  MiniStatusline.setup({
    content = { active = nil, inactive = nil },
    use_icons = true,
    set_vim_settings = true,
  })
end)

-- mini.tabline - Tabline showing buffers
now(function()
  require("mini.tabline").setup({
    show_icons = true,
    tabpage_section = "left",
    pad_in_active = true,
  })
end)

-- ============================================================================
-- Step One or Two (now_if_args) - Load immediately if file args, otherwise delay
-- ============================================================================

-- mini.files - File explorer
now_if_args(function()
  local mini_files = require("mini.files")
  mini_files.setup({
    options = {
      permanent_delete = true,
      use_as_default_explorer = true,
    },
    content = {
      filter = nil,
      prefix = nil,
    },
  })
  vim.keymap.set("n", "<C-y>", function()
    mini_files.open(vim.api.nvim_buf_get_name(0))
  end, { desc = "Open mini.files" })
  Config.new_autocmd("User", "MiniFilesBufferCreate", function(args)
    local buf_id = args.data.buf_id
    vim.keymap.set("n", "<C-y>", function()
      mini_files.close()
    end, { buffer = buf_id, desc = "Close mini.files" })
    vim.keymap.set("n", "<Esc>", function()
      mini_files.close()
    end, { buffer = buf_id, desc = "Close mini.files" })
    -- Split keymaps
    local map_split = function(buf, lhs, direction, desc)
      local rhs = function()
        local new_target_window
        vim.api.nvim_win_call(vim.api.nvim_get_current_win(), function()
          if direction == "vertical" then
            vim.cmd("vsplit")
          elseif direction == "horizontal" then
            vim.cmd("split")
          end
          new_target_window = vim.api.nvim_get_current_win()
        end)
        mini_files.set_target_window(new_target_window)
        mini_files.go_in({ close_on_file = true })
      end
      vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
    end
    map_split(buf_id, "<C-x>", "horizontal", "Split open")
    map_split(buf_id, "<C-v>", "vertical", "Vertical split open")
    -- Tab keymap
    vim.keymap.set("n", "<C-t>", function()
      local new_target_window
      vim.api.nvim_win_call(vim.api.nvim_get_current_win(), function()
        vim.cmd("tabnew")
        new_target_window = vim.api.nvim_get_current_win()
      end)
      mini_files.set_target_window(new_target_window)
      mini_files.go_in({ close_on_file = true })
    end, { buffer = buf_id, desc = "Open in new tab" })
    vim.keymap.set("n", "<CR>", function()
      mini_files.go_in({ close_on_file = true })
    end, { buffer = buf_id, desc = "Open file or enter directory" })
    vim.keymap.set("n", "g.", mini_files.synchronize, { buffer = buf_id, desc = "Synchronize" })
    vim.keymap.set("n", "g?", mini_files.show_help, { buffer = buf_id, desc = "Show help" })
  end, "Mini.files buffer keymaps")
end)

-- mini.misc - Miscellaneous useful functions
now_if_args(function()
  -- Makes `:h MiniMisc.put()` and `:h MiniMisc.put_text()` public
  require("mini.misc").setup()

  -- Change current working directory based on the current file path. It
  -- searches up the file tree until the first root marker ('.git' or 'Makefile')
  -- and sets their parent directory as a current directory.
  -- This is helpful when simultaneously dealing with files from several projects.
  MiniMisc.setup_auto_root()

  -- Restore latest cursor position on file open
  MiniMisc.setup_restore_cursor()

  -- Synchronize terminal emulator background with Neovim's background to remove
  -- possibly different color padding around Neovim instance
  MiniMisc.setup_termbg_sync()
end)

-- mini.completion - Completion and signature help
now_if_args(function()
  local process_items_opts = { kind_priority = { Text = -1, Snippet = 99 } }
  local process_items = function(items, base)
    return MiniCompletion.default_process_items(items, base, process_items_opts)
  end
  require("mini.completion").setup({
    lsp_completion = {
      source_func = "omnifunc",
      auto_setup = false,
      process_items = process_items,
    },
  })

  -- Set 'omnifunc' for LSP completion only when needed
  local on_attach = function(ev)
    vim.bo[ev.buf].omnifunc = "v:lua.MiniCompletion.completefunc_lsp"
  end
  Config.new_autocmd("LspAttach", nil, on_attach, "Set 'omnifunc'")
end)

-- ============================================================================
-- Step Two (later) - Delayed loaded after first screen
-- ============================================================================

-- mini.extra - Extra functionality for mini.nvim
later(function()
  require("mini.extra").setup()
  local MiniExtra = require("mini.extra")

  -- Keymaps for mini.pick + mini.extra
  vim.keymap.set("n", "<leader>f", function()
    MiniPick.builtin.files()
  end, { desc = "Find files" })
  vim.keymap.set("n", "<leader>/", function()
    MiniPick.builtin.grep_live()
  end, { desc = "Live grep" })
  vim.keymap.set("n", "<C-e>", function()
    MiniPick.builtin.buffers()
  end, { desc = "Find buffers" })
  vim.keymap.set("n", "<leader>bb", function()
    MiniPick.builtin.buffers()
  end, { desc = "Find buffers" })
  vim.keymap.set("n", "<leader>g", function()
    MiniExtra.pickers.git_files()
  end, { desc = "Git files" })
  vim.keymap.set("n", "<leader>o", function()
    MiniExtra.pickers.lsp({ scope = "document_symbol" })
  end, { desc = "Document symbols" })
  vim.keymap.set("n", "<leader>s", function()
    MiniExtra.pickers.lsp({ scope = "workspace_symbol_live" })
  end, { desc = "Workspace symbols" })
  vim.keymap.set("n", "<leader>d", function()
    MiniExtra.pickers.diagnostic()
  end, { desc = "Diagnostics" })
  vim.keymap.set("n", "<leader><space>", function()
    MiniExtra.pickers.history({ scope = ":" })
  end, { desc = "Command history" })
  vim.keymap.set("n", "<leader>'", function()
    MiniPick.builtin.resume()
  end, { desc = "Resume picker" })
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Goto definition" })
  vim.keymap.set("n", "gr", function()
    MiniExtra.pickers.lsp({ scope = "references" })
  end, { desc = "Goto references" })
  vim.keymap.set("n", "gi", function()
    MiniExtra.pickers.lsp({ scope = "implementation" })
  end, { desc = "Goto implementation" })
  vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, { desc = "Goto type definition" })
  vim.keymap.set("n", "<leader>E", function()
    MiniExtra.pickers.explorer()
  end, { desc = "File explorer" })
end)

-- mini.snippets - Snippet management
later(function()
  add({ "https://github.com/rafamadriz/friendly-snippets" })
  local snippets = require("mini.snippets")
  local config_path = vim.fn.stdpath("config")
  snippets.setup({
    snippets = {
      snippets.gen_loader.from_file(config_path .. "/snippets/global.json"),
      snippets.gen_loader.from_lang(),
    },
  })
  MiniSnippets.start_lsp_server()
end)

-- mini.keymap - Special key mappings for completion and pairs
later(function()
  require("mini.keymap").setup()
  -- Navigate completion menu with <Tab> / <S-Tab>
  MiniKeymap.map_multistep("i", "<Tab>", { "pmenu_next" })
  MiniKeymap.map_multistep("i", "<S-Tab>", { "pmenu_prev" })
  -- On <CR> try to accept current completion item, fall back to pairs
  MiniKeymap.map_multistep("i", "<CR>", { "pmenu_accept", "minipairs_cr" })
  -- On <BS> just try to account for pairs
  MiniKeymap.map_multistep("i", "<BS>", { "minipairs_bs" })
end)

-- mini.ai - Extend and create text objects
later(function()
  require("mini.ai").setup({
    n_lines = 500,
    custom_textobjects = {
      o = require("mini.ai").gen_spec.treesitter({
        a = { "@block.outer", "@conditional.outer", "@loop.outer" },
        i = { "@block.inner", "@conditional.inner", "@loop.inner" },
      }),
      f = require("mini.ai").gen_spec.treesitter({
        a = "@function.outer",
        i = "@function.inner",
      }),
      c = require("mini.ai").gen_spec.treesitter({
        a = "@class.outer",
        i = "@class.inner",
      }),
      t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
      d = { "%f[%d]%d+" },
      e = {
        {
          "%u[%l%d]+%f[^%l%d]",
          "%f[%S][%l%d]+%f[^%l%d]",
          "%f[%P][%l%d]+%f[^%l%d]",
          "^[%l%d]+%f[^%l%d]",
        },
        "^().*()$",
      },
      u = require("mini.ai").gen_spec.function_call(),
      U = require("mini.ai").gen_spec.function_call({ name_pattern = "[%w_]" }),
    },
  })
end)

-- mini.align - Align text interactively
later(function()
  require("mini.align").setup({
    -- Module mappings. Use `''` (empty string) to disable one.
    mappings = {
      start = "ga",
      start_with_preview = "gA",
    },
    -- Modifiers changing alignment steps and/or options
    modifiers = {
      -- Main option modifiers
      ["s"] = function(steps, opts)
        opts.split_pattern = "%s+"
        table.insert(steps.pre, require("mini.align").gen_step.trim())
      end,
      ["t"] = function(steps, opts)
        local delimiters = {
          [[=]],
          [[=>]],
          [[//=]],
          [[!==]],
          [[==]],
          [[%=]],
          [[/=]],
          [[-=]],
          [[+=]],
          [[*=]],
          [[&=]],
          [[|=]],
          [[^=]],
          [[%=]],
          [[:=]],
          [[::=]],
          [[<-]],
          [[->]],
          [[=>]],
          [[>]],
          [[<]],
          [[>=]],
          [[<=]],
          [[~=]],
        }
        opts.split_pattern = "(" .. vim.fn.join(delimiters, "|") .. ")"
      end,
      [","] = function(steps, opts)
        opts.split_pattern = ","
        table.insert(steps.pre, require("mini.align").gen_step.trim())
      end,
      ["|"] = function(steps, opts)
        opts.split_pattern = "|"
        table.insert(steps.pre, require("mini.align").gen_step.trim())
      end,
      [" "] = function(steps, opts)
        table.insert(steps.pre, require("mini.align").gen_step.normalize_ws())
        opts.merge_delimiter = " "
      end,
      -- Option-modifier modifiers
      ["j"] = function(steps, opts)
        opts.justify_side = "left"
      end,
      ["J"] = function(steps, opts)
        opts.justify_side = "right"
      end,
      ["m"] = function(steps, opts)
        opts.justify_side = "center"
      end,
    },
    -- Default options controlling alignment process
    options = {
      split_pattern = "",
      justify_side = "left",
      merge_delimiter = "",
    },
    -- Steps performed in order (use default steps)
  })
end)

-- mini.bracketed - Navigate with bracket mappings
later(function()
  require("mini.bracketed").setup({
    buffer = { suffix = "b", options = {} },
    comment = { suffix = "c", options = {} },
    conflict = { suffix = "x", options = {} },
    diagnostic = { suffix = "d", options = {} },
    file = { suffix = "f", options = {} },
    indent = { suffix = "i", options = {} },
    jump = { suffix = "j", options = {} },
    location = { suffix = "l", options = {} },
    oldfile = { suffix = "o", options = {} },
    quickfix = { suffix = "q", options = {} },
    treesitter = { suffix = "t", options = {} },
    undo = { suffix = "u", options = {} },
    window = { suffix = "w", options = {} },
    yank = { suffix = "y", options = {} },
  })
end)

-- mini.bufremove - Remove buffers without closing windows
later(function()
  require("mini.bufremove").setup()
  vim.keymap.set("n", "<leader>bd", "<cmd>lua MiniBufremove.delete()<cr>", { desc = "Delete buffer" })
  vim.keymap.set("n", "<leader>bD", "<cmd>lua MiniBufremove.delete(0, true)<cr>", { desc = "Delete buffer (force)" })
  vim.keymap.set("n", "<leader>bw", "<cmd>lua MiniBufremove.wipeout()<cr>", { desc = "Wipeout buffer" })
end)

-- mini.clue - Keybinding hints
later(function()
  local miniclue = require("mini.clue")
  miniclue.setup({
    triggers = {
      -- Leader triggers
      { mode = { "n", "x" }, keys = "<Leader>" },
      -- `[` and `]` keys
      { mode = "n", keys = "[" },
      { mode = "n", keys = "]" },
      -- Built-in completion
      { mode = "i", keys = "<C-x>" },
      -- `g` key
      { mode = { "n", "x" }, keys = "g" },
      -- Marks
      { mode = { "n", "x" }, keys = "'" },
      { mode = { "n", "x" }, keys = "`" },
      -- Registers
      { mode = { "n", "x" }, keys = '"' },
      { mode = { "i", "c" }, keys = "<C-r>" },
      -- Window commands
      { mode = "n", keys = "<C-w>" },
      -- `z` key
      { mode = { "n", "x" }, keys = "z" },
    },
    clues = {
      miniclue.gen_clues.square_brackets(),
      miniclue.gen_clues.builtin_completion(),
      miniclue.gen_clues.g(),
      miniclue.gen_clues.marks(),
      miniclue.gen_clues.registers(),
      miniclue.gen_clues.windows(),
      miniclue.gen_clues.z(),
      { mode = "n", keys = "<Leader>b", desc = "Buffer" },
      { mode = "n", keys = "<Leader>t", desc = "Test" },
      { mode = "n", keys = "<Leader>C", desc = "CodeDiff" },
      { mode = "n", keys = "<Leader>D", desc = "Debug" },
      { mode = "n", keys = "<Leader>G", desc = "Git" },
      { mode = "n", keys = "<Leader>K", desc = "Kulala (HTTP)" },
      { mode = "n", keys = "<Leader>O", desc = "Overseer" },
      { mode = "n", keys = "<Leader>S", desc = "Session" },
      { mode = "n", keys = "<Leader>T", desc = "Toggle/Trim" },
      { mode = "n", keys = "<Leader>X", desc = "Trouble" },
    },
    window = {
      config = {},
      delay = 500,
      scroll_down = "<C-d>",
      scroll_up = "<C-u>",
    },
  })
end)

-- mini.cmdline - Better command line UI
later(function()
  require("mini.cmdline").setup({
    min_width = 60,
    max_height = 10,
    animation = true,
    use_icons = true,
    prompts = {
      [":"] = { prompt = ">" },
      ["/"] = { prompt = "/" },
      ["?"] = { prompt = "?" },
      ["=@"] = { prompt = "=" },
    },
    window = {
      config = { border = "single" },
      relative = "cursor",
    },
    completion = {
      enabled = true,
      max_items = 50,
      fuzzy = true,
      builtin_sources = {
        commands = 90,
        history = 80,
        file = 70,
        help = 60,
        lua = 50,
        shell = 40,
        var = 30,
      },
    },
    search = {
      show_count = true,
      highlight_matches = true,
    },
  })
end)

-- mini.comment - Comment operations
later(function()
  require("mini.comment").setup({
    options = {
      custom_commentstring = nil,
      ignore_blank_line = false,
      start_of_line = false,
      pad_comment_parts = true,
    },
    mappings = {
      comment = "gc",
      comment_line = "gcc",
      comment_visual = "gc",
      textobject = "gc",
    },
  })
end)

-- mini.cursorword - Highlight word under cursor
later(function()
  require("mini.cursorword").setup()
end)

-- mini.indentscope - Indent scope visualization
later(function()
  require("mini.indentscope").setup({
    symbol = "╎",
    draw = {
      delay = 0,
      animation = function()
        return 0
      end,
    },
    options = {
      try_as_border = true,
    },
  })
end)

-- mini.diff - Git diff highlighting
later(function()
  local mini_diff = require("mini.diff")
  mini_diff.setup({
    view = {
      style = "sign",
      signs = {
        add = "▌",
        change = "▌",
        delete = "▁",
      },
    },
    mappings = {
      apply = "gh",
      reset = "gH",
      textobject = "gh",
    },
  })
  vim.keymap.set("n", "<leader>Gd", function()
    mini_diff.toggle_overlay(0)
  end, { desc = "Toggle diff overlay" })
  vim.keymap.set("n", "<leader>Gh", function()
    mini_diff.toggle_overlay(0)
  end, { desc = "Toggle diff overlay" })
  vim.keymap.set("n", "]g", function()
    mini_diff.goto_hunk("next")
  end, { desc = "Next git hunk" })
  vim.keymap.set("n", "[g", function()
    mini_diff.goto_hunk("prev")
  end, { desc = "Prev git hunk" })
end)

-- mini.git - Git integration
later(function()
  require("mini.git").setup()
  vim.keymap.set("n", "<leader>Gb", "<cmd>lua MiniGit.show_at_cursor()<cr>", { desc = "Git blame at cursor" })
  vim.keymap.set("n", "<leader>GB", "<cmd>lua MiniGit.show_range_history()<cr>", { desc = "Git blame range" })
end)

-- mini.hipatterns - Highlight patterns in text
later(function()
  local hipatterns = require("mini.hipatterns")
  hipatterns.setup({
    highlighters = {
      hex_color = hipatterns.gen_highlighter.hex_color(),
      fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
      hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
      todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
      note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
    },
  })
end)

-- mini.jump - Improved f/F/t/T jumps
-- later(function()
--   require("mini.jump").setup()
-- end)

-- mini.jump2d - Jump to any location on screen
later(function()
  local jump2d = require("mini.jump2d")
  jump2d.setup({
    spotter = jump2d.builtin_opts.word_start.spotter,
    labels = "abcdefghijklmnopqrstuvwxyz",
    view = {
      n_steps_ahead = 999,
      dim = false,
    },
    mappings = { start_jumping = "" },
  })
  vim.keymap.set({ "n", "x", "o" }, "gw", function()
    jump2d.start(jump2d.builtin_opts.word_start)
  end, { desc = "Jump to word start" })
  vim.keymap.set({ "n", "x", "o" }, "gl", function()
    jump2d.start(jump2d.builtin_opts.line_start)
  end, { desc = "Jump to line start" })
end)

-- mini.move - Move lines and selections
later(function()
  require("mini.move").setup({
    mappings = {
      left = "<M-h>",
      right = "<M-l>",
      down = "<M-j>",
      up = "<M-k>",
      line_left = "<M-h>",
      line_right = "<M-l>",
      line_down = "<M-j>",
      line_up = "<M-k>",
    },
  })
end)

-- mini.operators - Text manipulation operators
later(function()
  require("mini.operators").setup({
    evaluate = { prefix = "g=" },
    exchange = { prefix = "gx", reindent_linewise = true },
    multiply = { prefix = "gm" },
    replace = { prefix = "gM", reindent_linewise = true },
    sort = { prefix = "gs" },
  })
end)

-- mini.pairs - Auto pairs
later(function()
  local mini_pairs = require("mini.pairs")
  mini_pairs.setup({
    modes = { insert = true, command = false, terminal = false },
    mappings = {
      ["("] = { action = "open", pair = "()", neigh_pattern = "[^\\]." },
      ["["] = { action = "open", pair = "[]", neigh_pattern = "[^\\]." },
      ["{"] = { action = "open", pair = "{}", neigh_pattern = "[^\\]." },
      [")"] = { action = "close", pair = "()", neigh_pattern = "[^\\]." },
      ["]"] = { action = "close", pair = "[]", neigh_pattern = "[^\\]." },
      ["}"] = { action = "close", pair = "{}", neigh_pattern = "[^\\]." },
      ['"'] = { action = "closeopen", pair = '""', neigh_pattern = "[^\\].", register = { cr = false } },
      ["'"] = { action = "closeopen", pair = "''", neigh_pattern = "[^%a\\].", register = { cr = false } },
      ["`"] = { action = "closeopen", pair = "``", neigh_pattern = "[^\\].", register = { cr = false } },
    },
  })
end)
-- Disable single quotes in Rust files
Config.new_autocmd("FileType", "rust", function()
  vim.keymap.set("i", "'", "'", { buffer = true })
end, "Disable single quotes in Rust")

-- mini.pick - General purpose interactive picker
later(function()
  require("mini.pick").setup({
    delay = { async = 10, busy = 50 },
    window = {
      config = { border = "single" },
      prompt_prefix = "> ",
    },
    mappings = {
      send_all_to_qf = {
        char = "<C-q>",
        func = function()
          local matches = MiniPick.get_picker_matches()
          if not matches or not matches.all then
            return
          end
          MiniPick.default_choose_marked(matches.all)
          MiniPick.stop()
        end,
      },
    },
  })
  MiniPick = require("mini.pick")
end)

-- mini.splitjoin - Split and join arguments
later(function()
  require("mini.splitjoin").setup({
    detect = {
      brackets = { "()", "[]", "{}" },
      separator = ",",
      add_trailing_separator = false,
      recursive = false,
    },
  })
end)

-- mini.surround - Surround operations
later(function()
  require("mini.surround").setup({
    mappings = {
      add = "ms",
      delete = "md",
      find = "mf",
      find_left = "mF",
      highlight = "mh",
      replace = "mr",
      suffix_last = "l",
      suffix_next = "n",
    },
    respect_selection_type = true,
  })
end)

-- mini.trailspace - Trailing whitespace handling
later(function()
  require("mini.trailspace").setup()
  vim.keymap.set("n", "<leader>Tw", "<cmd>lua MiniTrailspace.trim()<cr>", { desc = "Trim trailing whitespace" })
  vim.keymap.set(
    "n",
    "<leader>TW",
    "<cmd>lua MiniTrailspace.trim_last_lines()<cr>",
    { desc = "Trim trailing empty lines" }
  )
end)

-- mini.visits - Track and navigate visited file locations
later(function()
  local mini_visits = require("mini.visits")
  mini_visits.setup({
    -- How many visits to remember per path
    list = {
      -- Sort by most recent visits first
      sort = nil,
    },
    -- Store visits data
    store = {
      -- Use default path: vim.fn.stdpath('data') .. '/mini-visits'
      path = nil,
    },
  })

  -- Keymaps for mini.visits
  -- Open picker with recent files/locations
  vim.keymap.set("n", "<leader>v", function()
    MiniVisits.select_path()
  end, { desc = "Visits: Select recent location" })

  -- Add a visit for current location
  vim.keymap.set("n", "<leader>va", function()
    MiniVisits.add_label()
  end, { desc = "Visits: Add label to current location" })

  -- Remove a visit for current location
  vim.keymap.set("n", "<leader>vr", function()
    MiniVisits.remove_label()
  end, { desc = "Visits: Remove label from current location" })

  -- List all labeled locations
  vim.keymap.set("n", "<leader>vl", function()
    MiniVisits.select_label()
  end, { desc = "Visits: Select labeled location" })
end)
