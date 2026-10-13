-- Telescope: give code previews room; stack them on narrower terminals.
require("telescope").setup({
	defaults = {
		prompt_prefix = "⌕  ",
		selection_caret = "❯ ",
		dynamic_preview_title = true,
		layout_strategy = "flex",
		layout_config = {
			width = 0.96,
			height = 0.90,
			flex = { flip_columns = 110 },
			horizontal = { preview_width = 0.65 },
			vertical = { preview_height = 0.55 },
		},
	},
})
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
vim.keymap.set("n", "<leader>fz", builtin.current_buffer_fuzzy_find, { desc = "Telescope current buffer" })
vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Telescope document symbols" })
