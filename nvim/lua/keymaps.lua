-- Leader Key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Leader Keymaps
vim.keymap.set("v", "<leader>r", ":<C-u>WEZSENDSELECTION<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>b", ":<C-u>WEZSENDBLOCK<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>p", ":<C-u>w | !python3 %<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>q", ":<C-u>q<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>w", ":<C-u>w<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory with Oil" })
vim.g.copilot_no_tab_map = true
vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
