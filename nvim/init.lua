-- Requirements
require("keymaps")
require("config.lazy")
require("repl")


-- Basic Settings
vim.cmd("syntax on")
vim.opt.number = true
vim.lsp.enable("pyright")


-- Custom Functions
require("llm").setup_keymaps()
vim.cmd.colorscheme("catppuccin")


