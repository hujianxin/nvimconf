-- ============================================================================
-- Built-in Neovim Options (plugin/10_options.lua)
-- ============================================================================

-- Disable unused providers to speed up startup
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Leader key
vim.g.mapleader = " "

-- Editor behavior
vim.opt.encoding = "utf-8"
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.updatetime = 300
vim.opt.signcolumn = "yes"
vim.opt.mouse = "a"
vim.opt.synmaxcol = 200
vim.opt.shortmess:append("c")

-- Neovim 0.12+ defaults
vim.opt.shelltemp = false
vim.opt.diffopt = "internal,filler,closeoff,indent-heuristic,linematch:60,inline:char"

-- Diagnostics (Neovim 0.12+)
local sev = vim.diagnostic.severity
vim.diagnostic.config({
  severity_sort = true,
  update_in_insert = false,
  virtual_text = {
    severity = { min = sev.WARN },
    source = "if_many",
    spacing = 4,
  },
  float = {
    border = "rounded",
    source = true,
    severity_sort = true,
  },
  signs = {
    text = {
      [sev.ERROR] = "E",
      [sev.WARN] = "W",
      [sev.INFO] = "I",
      [sev.HINT] = "H",
    },
  },
})

-- UI settings
vim.opt.number = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 0
vim.opt.showcmd = false
vim.opt.showmode = false
vim.opt.termguicolors = true
vim.opt.background = "dark"

-- Window splitting
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.splitkeep = "screen"

-- Indentation and formatting
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.wrap = true
vim.opt.shiftround = true

-- Search settings
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Clipboard and undo
vim.opt.clipboard = "unnamedplus"
vim.opt.undolevels = 10000
vim.opt.undofile = true

-- Timing settings
vim.opt.timeout = true
vim.opt.timeoutlen = 300

-- Misc
vim.opt.wildignorecase = true
vim.opt.cursorline = true

-- Enable filetype plugins and syntax
vim.cmd("filetype plugin indent on")
if vim.fn.exists("syntax_on") ~= 1 then
  vim.cmd("syntax enable")
end

-- UI2 (Neovim 0.12+ experimental)
local ok, ui2 = pcall(require, "vim._core.ui2")
if ok and ui2 then
  ui2.enable()
end
