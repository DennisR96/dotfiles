-- GitHub Copilot
require("copilot").setup({
	 suggestion = { enabled = true, auto_trigger = true, keymap = { accept = false } },
	 panel = { enabled = false },
})
vim.keymap.set("i", "<C-J>", function()
	require("copilot.suggestion").accept()
end, { silent = true })
vim.keymap.set("i", "<C-n>", function()
	require("copilot.suggestion").next()
end, { silent = true })
vim.keymap.set("i", "<C-p>", function()
	require("copilot.suggestion").prev()
end, { silent = true })
vim.keymap.set("i", "<C-e>", function()
	require("copilot.suggestion").dismiss()
end, { silent = true })
