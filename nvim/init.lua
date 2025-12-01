-- Clipboard
vim.opt.clipboard = "unnamedplus"

-- Requirements
require("keymaps")
require("config.lazy")

-- Basic Settings
vim.cmd("syntax on")
vim.opt.number = true
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"
vim.lsp.enable("pyright")

-- Custom Functions
vim.cmd.colorscheme("catppuccin-frappe")
