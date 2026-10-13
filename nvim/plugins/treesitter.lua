-- Treesitter (current nvim-treesitter API; requires Neovim 0.12+).
-- Install common web languages plus the languages used regularly.
local parsers = {
	"bash",
	"c",
	"c_sharp",
	"cpp",
	"css",
	"html",
	"javascript",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"python",
	"rust",
	"scss",
	"tsx",
	"typescript",
	"yaml",
}
require("nvim-treesitter").setup()
require("nvim-treesitter").install(parsers)

-- Try Treesitter for every filetype; uninstalled/unsupported parsers simply fall back.
vim.api.nvim_create_autocmd("FileType", {
	callback = function(args)
		pcall(vim.treesitter.start, args.buf)
	end,
})
