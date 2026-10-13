-- Cutlass
require("cutlass").setup({
	cut_key = "x",
	override_del = true,
	exclude = {},
	registers = { select = "_", delete = "_", change = "_" },
})
