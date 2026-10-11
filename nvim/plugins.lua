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
	"https://github.com/nvim-treesitter/nvim-treesitter",
}, { load = true })

-- Catppuccin
require("catppuccin").setup({ transparent_background = true })
vim.cmd.colorscheme("catppuccin-frappe")

-- Copilot
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
	filetypes = { ["*"] = true },
})

-- Cutlass
require("cutlass").setup({
	cut_key = "x",
	override_del = true,
	exclude = {},
	registers = { select = "_", delete = "_", change = "_" },
})

-- Conform
require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "black" },
		rust = { "rustfmt", lsp_format = "fallback" },
		javascript = { "prettierd", "prettier", stop_after_first = true },
	},
	format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
})

-- nvim-cmp
local cmp = require("cmp")
cmp.setup({
	sources = { { name = "nvim_lsp" } },
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

-- LSP
require("mason").setup()
require("mason-lspconfig").setup({ ensure_installed = { "lua_ls" } })
vim.lsp.config("*", { capabilities = require("cmp_nvim_lsp").default_capabilities() })

-- Oil
require("mini.icons").setup()
require("oil").setup({
	delete_to_trash = true,
	columns = { "icon" },
	view_options = { show_hidden = true },
})
local size_ns = vim.api.nvim_create_namespace("oil_file_sizes")
local size_generation = {}
local function format_size(size)
	if size < 0 then
		return nil
	elseif size >= 1e9 then
		return string.format("%.1fG", size / 1e9)
	elseif size >= 1e6 then
		return string.format("%.1fM", size / 1e6)
	elseif size >= 1e3 then
		return string.format("%.1fK", size / 1e3)
	else
		return tostring(size)
	end
end
local function show_file_sizes(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= "oil" then
		return
	end
	local oil = require("oil")
	local dir = oil.get_current_dir(bufnr)
	if not dir then
		return
	end
	size_generation[bufnr] = (size_generation[bufnr] or 0) + 1
	local generation = size_generation[bufnr]
	vim.api.nvim_buf_clear_namespace(bufnr, size_ns, 0, -1)
	for lnum = 1, vim.api.nvim_buf_line_count(bufnr) do
		local entry = oil.get_entry_on_line(bufnr, lnum)
		if entry and entry.type == "file" then
			local row, path = lnum - 1, dir .. entry.name
			vim.uv.fs_stat(path, function(err, stat)
				if err or not stat then
					return
				end
				vim.schedule(function()
					if
						not vim.api.nvim_buf_is_valid(bufnr)
						or size_generation[bufnr] ~= generation
						or oil.get_current_dir(bufnr) ~= dir
					then
						return
					end
					local size = format_size(stat.size)
					if size then
						vim.api.nvim_buf_set_extmark(bufnr, size_ns, row, 0, {
							virt_text = { { "  " .. size, "Comment" } },
							virt_text_pos = "eol",
						})
					end
				end)
			end)
		end
	end
end
local function schedule_file_sizes(bufnr)
	vim.schedule(function()
		show_file_sizes(bufnr)
	end)
end
vim.api.nvim_create_autocmd("User", {
	pattern = "OilEnter",
	callback = function(args)
		schedule_file_sizes(args.data and args.data.buf or 0)
	end,
})
vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged" }, {
	callback = function(args)
		if vim.bo[args.buf].filetype == "oil" then
			schedule_file_sizes(args.buf)
		end
	end,
})

-- Telescope
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
vim.keymap.set("n", "<leader>fz", builtin.current_buffer_fuzzy_find, { desc = "Telescope current buffer" })
vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Telescope document symbols" })

-- Treesitter (current nvim-treesitter API; requires Neovim 0.12+).
local parsers = { "python", "lua", "rust", "javascript", "typescript", "html", "css", "latex" }
require("nvim-treesitter").setup()
require("nvim-treesitter").install(parsers)
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "python", "lua", "rust", "javascript", "typescript", "html", "css", "tex" },
	callback = function(args)
		pcall(vim.treesitter.start, args.buf)
	end,
})

-- Copy selected Oil file contents to the clipboard.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "oil",
	callback = function()
		vim.keymap.set("v", "gy", function()
			local oil = require("oil")
			local dir = oil.get_current_dir()
			if not dir then
				return
			end
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
			vim.schedule(function()
				local start_line, end_line = vim.fn.getpos("'<")[2], vim.fn.getpos("'>")[2]
				local bufnr, paths = vim.api.nvim_get_current_buf(), {}
				for i = start_line, end_line do
					local entry = oil.get_entry_on_line(bufnr, i)
					if entry and entry.type == "file" then
						paths[#paths + 1] = dir .. entry.name
					end
				end
				if #paths == 0 then
					return
				end
				local script = [[import pathlib, sys
for name in sys.argv[1:]:
    path = pathlib.Path(name)
    print(f"### {path.name}")
    try:
        print(path.read_text(), end="\n")
    except (UnicodeError, OSError) as error:
        print(f"[Could not read file: {error}]")
    print()]]
				vim.system({ "python3", "-c", script, unpack(paths) }, { text = true }, function(result)
					vim.schedule(function()
						if result.code ~= 0 then
							vim.notify(result.stderr or "Failed to read selected files", vim.log.levels.ERROR)
							return
						end
						vim.fn.setreg("+", result.stdout or "")
						vim.notify("Yanked contents of selected files to clipboard")
					end)
				end)
			end)
		end, { buffer = true, desc = "Yank file contents to clipboard" })
	end,
})
