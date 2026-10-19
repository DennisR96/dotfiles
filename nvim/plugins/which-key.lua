-- which-key
require("which-key").setup()
require("which-key").add({
	{ "<leader>d", group = "debug / diff" },
	{ "<leader>f", group = "find" },
})
