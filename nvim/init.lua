-- Basic Configuration
vim.opt.clipboard = "unnamedplus"
vim.opt.number = true
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"

-- Enable Treesitter folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

-- Set default fold levels so files do not open completely folded
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

-- Leader Configuration
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Indentation Settings
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2

-- Keymaps
vim.keymap.set("n", "<leader>p", ":<C-u>w | !python3 %<CR>", { silent = true })
vim.keymap.set("n", "<leader>q", ":<C-u>q<CR>", { silent = true })
vim.keymap.set("n", "<leader>w", ":<C-u>w<CR>", { silent = true })
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory with Oil" })
vim.keymap.set("x", "p", "P")

-- Fold navigation via arrow keys
vim.keymap.set("n", "fo", "zo", { desc = "Open fold under cursor" })
vim.keymap.set("n", "fc", "zc", { desc = "Close fold under cursor" })
vim.keymap.set("n", "fj", "zj", { desc = "Jump to next fold" })
vim.keymap.set("n", "fk", "zk", { desc = "Jump to previous fold" })

-- Shift + Arrow keys for global folding
vim.keymap.set("n", "fR", "zR", { desc = "Open all folds in file" })
vim.keymap.set("n", "fM", "zM", { desc = "Close all folds in file" })

-- Disable Single Line Jumps
vim.keymap.set("n", "j", "gj", opts)
vim.keymap.set("n", "k", "gk", opts)

-- Also remap for visual mode
vim.keymap.set("v", "j", "gj", opts)
vim.keymap.set("v", "k", "gk", opts)

-- Lazy.nvim Setup
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin Setup
local plugins = {
	-- Catppuccin (Theme)
	{
		"catppuccin/nvim",
		name = "catppuccin",
		config = function()
			require("catppuccin").setup({
				transparent_background = true,
			})
			vim.cmd.colorscheme("catppuccin-frappe")
		end,
	},

	-- Copilot
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = {
					enabled = true,
					auto_trigger = true,
					keymap = {
						accept = "<C-J>",
						accept_word = false,
						accept_line = false,
						next = "<C-n>",
						prev = "<C-p>",
						dismiss = "<C-e>",
					},
				},
				filetypes = {
					["*"] = true,
				},
			})
		end,
	},

	-- Cutlass
	{
		"gbprod/cutlass.nvim",
		opts = {
			cut_key = "x",
			override_del = true,
			exclude = {},
			registers = {
				select = "_",
				delete = "_",
				change = "_",
			},
		},
	},

	-- Conform
	{
		"stevearc/conform.nvim",
		opts = {},
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "isort", "black" },
					rust = { "rustfmt", lsp_format = "fallback" },
					javascript = { "prettierd", "prettier", stop_after_first = true },
				},
				format_on_save = {
					timeout_ms = 500,
					lsp_format = "fallback",
				},
			})
		end,
	},

	-- nvim-cmp
	{
		"hrsh7th/nvim-cmp",
		config = function()
			local cmp = require("cmp")
			cmp.setup({
				sources = {
					{ name = "nvim_lsp" },
				},
				mapping = cmp.mapping.preset.insert({
					["<C-p>"] = cmp.mapping.select_prev_item({ behavior = "select" }),
					["<C-n>"] = cmp.mapping.select_next_item({ behavior = "select" }),
					["<CR>"] = cmp.mapping.confirm({ select = false }),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-u>"] = cmp.mapping.scroll_docs(-4),
					["<C-d>"] = cmp.mapping.scroll_docs(4),
				}),
				snippet = {
					expand = function(args)
						vim.snippet.expand(args.body)
					end,
				},
			})
		end,
	},

	-- nvim-lspconfig
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = { "lua_ls" },
			})
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			vim.lsp.config("*", { capabilities = capabilities })
		end,
	},

	-- Oil
	{
		"stevearc/oil.nvim",
		dependencies = { { "nvim-mini/mini.icons", opts = {} } },
		lazy = false,
		config = function()
			require("oil").setup({
				delete_to_trash = true,
				view_options = { show_hidden = true },
			})
		end,
	},

	-- Surround
	{ "kylechui/nvim-surround" },

	-- Telescope
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		config = function()
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
		end,
	},

	-- Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		opts = {
			ensure_installed = { "python", "lua", "rust", "javascript", "typescript", "html", "css", "latex" },
			indent = { enable = true }, ---@type lazyvim.TSFeat
			highlight = { enable = true }, ---@type lazyvim.TSFeat
			folds = { enable = true },
		},
		config = function(_, opts)
			require("nvim-treesitter.config").setup(opts)
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "*",
				callback = function()
					pcall(vim.treesitter.start)
				end,
			})
		end,
	},
}

require("lazy").setup(plugins)

vim.api.nvim_create_autocmd("FileType", {
	pattern = "oil",
	callback = function()
		vim.keymap.set("v", "gy", function()
			local oil = require("oil")
			local dir = oil.get_current_dir()
			if not dir then
				return
			end

			-- Send <Esc> to exit visual mode and update the '< and '> marks
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

			vim.schedule(function()
				local start_line = vim.fn.getpos("'<")[2]
				local end_line = vim.fn.getpos("'>")[2]
				local bufnr = vim.api.nvim_get_current_buf()
				local contents = {}

				for i = start_line, end_line do
					local entry = oil.get_entry_on_line(bufnr, i)
					if entry and entry.type == "file" then
						local filepath = dir .. entry.name
						local lines = vim.fn.readfile(filepath)

						table.insert(contents, "### " .. entry.name)
						for _, line in ipairs(lines) do
							table.insert(contents, line)
						end
						table.insert(contents, "")
					end
				end

				if #contents > 0 then
					local text = table.concat(contents, "\n")
					vim.fn.setreg("+", text)
					vim.notify("Yanked contents of selected files to clipboard")
				end
			end)
		end, { buffer = true, desc = "Yank file contents to clipboard" })
	end,
})
