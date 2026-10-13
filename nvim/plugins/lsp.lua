-- LSP
require("mason").setup()
require("mason-lspconfig").setup({
	ensure_installed = { "lua_ls", "ts_ls", "roslyn_ls" },
	automatic_enable = false,
})
vim.lsp.config("*", { capabilities = require("cmp_nvim_lsp").default_capabilities() })
vim.lsp.enable({ "lua_ls", "ts_ls", "roslyn_ls" })
