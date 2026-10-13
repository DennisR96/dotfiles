-- which-key
require("which-key").setup()
require("which-key").add({
	{ "<leader>d", group = "diff" },
	{ "<leader>f", group = "find" },
})
