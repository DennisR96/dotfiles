-- Install and load plugins with Neovim's built-in package manager.
vim.pack.add({
	{ src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
	"https://github.com/zbirenbaum/copilot.lua",
	"https://github.com/gbprod/cutlass.nvim",
	"https://github.com/stevearc/conform.nvim",
	"https://github.com/hrsh7th/nvim-cmp",
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/williamboman/mason.nvim",
	"https://github.com/williamboman/mason-lspconfig.nvim",
	"https://github.com/hrsh7th/cmp-nvim-lsp",
	"https://github.com/stevearc/oil.nvim",
	"https://github.com/nvim-mini/mini.icons",
	"https://github.com/nvim-telescope/telescope.nvim",
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/esmuellert/codediff.nvim",
	"https://github.com/folke/which-key.nvim",
	"https://github.com/nvim-treesitter/nvim-treesitter",
	"https://github.com/olimorris/codecompanion.nvim",
}, { load = true })

-- Keep load order explicit: the theme and icon provider precede their consumers.
local config = vim.fn.stdpath("config")
dofile(config .. "/plugins/codecompanion.lua")
dofile(config .. "/plugins/catppuccin.lua")
dofile(config .. "/plugins/copilot.lua")
dofile(config .. "/plugins/cutlass.lua")
dofile(config .. "/plugins/conform.lua")
dofile(config .. "/plugins/cmp.lua")
dofile(config .. "/plugins/lsp.lua")
dofile(config .. "/plugins/oil.lua")
dofile(config .. "/plugins/which-key.lua")
dofile(config .. "/plugins/codediff.lua")
dofile(config .. "/plugins/telescope.lua")
dofile(config .. "/plugins/treesitter.lua")
