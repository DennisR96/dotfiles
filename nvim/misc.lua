-- `@` alone in 'isfname' means alphabetic characters, not the literal @.
-- Include the literal so gf passes the full "@/..." path to includeexpr.
vim.opt.isfname:append("@-@")

-- Show only the current file's basename for each tab page.
_G.file_tabline = function()
	local labels = {}
	for number, tab in ipairs(vim.api.nvim_list_tabpages()) do
		local win = vim.api.nvim_tabpage_get_win(tab)
		local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
		local label = name == "" and "[No Name]" or vim.fn.fnamemodify(name, ":t")
		local highlight = tab == vim.api.nvim_get_current_tabpage() and "%#TabLineSel#" or "%#TabLine#"
		labels[#labels + 1] = highlight .. "%" .. number .. "T " .. label:gsub("%%", "%%%%") .. " "
	end
	return table.concat(labels) .. "%#TabLineFill#%T"
end

vim.o.tabline = "%!v:lua.file_tabline()"

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		if vim.g.colors_name == "catppuccin-frappe" then
			vim.api.nvim_set_hl(0, "TabLineSel", { fg = "#303446", bg = "#8caaee", bold = true })
		end
	end,
})

_G.resolve_js_import = function(fname)
	if not fname:match("^@/") then
		return fname
	end

	local root = vim.fs.root(0, { "jsconfig.json", "tsconfig.json", "package.json", ".git" })
	if not root then
		return fname
	end

	return root .. "/src/" .. fname:sub(3)
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
	callback = function()
		vim.opt_local.includeexpr = "v:lua.resolve_js_import(v:fname)"
		vim.opt_local.suffixesadd = { ".js", ".jsx", ".ts", ".tsx" }
	end,
})
