-- This config uses vim.pack and the modern LSP API (Neovim 0.12+).
if vim.fn.has("nvim-0.12") ~= 1 then
	vim.api.nvim_err_writeln(
		"This config requires Neovim >= 0.12. On Ubuntu/Debian, apt often installs an old Neovim; install a newer release and run `nvim --version`."
	)
	return
end

local config = vim.fn.stdpath("config")
dofile(config .. "/options.lua")
dofile(config .. "/keymaps.lua")
dofile(config .. "/plugins.lua")

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		dofile(config .. "/start-screen.lua")
	end,
})
