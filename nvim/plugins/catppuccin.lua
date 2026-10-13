-- Catppuccin
require("catppuccin").setup({
	transparent_background = true,
	custom_highlights = function(colors)
		-- Telescope floats should use the same transparent background as the editor.
		return {
			TelescopeNormal = { fg = colors.text, bg = "NONE" },
			TelescopeBorder = { fg = colors.blue, bg = "NONE" },
			TelescopeTitle = { fg = colors.subtext0, bg = "NONE" },
		}
	end,
})
vim.cmd.colorscheme("catppuccin-frappe")
