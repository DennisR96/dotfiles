local opts = { silent = true }

-- Keymaps
vim.keymap.set("n", "<leader>p", function()
	vim.cmd.write()
	local file = vim.api.nvim_buf_get_name(0)
	vim.system({ "python3", file }, { text = true }, function(result)
		vim.schedule(function()
			if result.stdout and result.stdout ~= "" then
				vim.notify(result.stdout)
			end
			if result.stderr and result.stderr ~= "" then
				vim.notify(result.stderr, vim.log.levels.ERROR)
			end
		end)
	end)
end, { desc = "Save and run Python file" })
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
