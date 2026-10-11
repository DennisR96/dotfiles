-- RAEK dashboard for a plain `nvim` launch (no file arguments).
if vim.fn.argc() ~= 0 then
	return
end

local logo = {
	"███████████     █████████   ██████████ █████   ████",
	"░░███░░░░░███   ███░░░░░███ ░░███░░░░░█░░███   ███░",
	" ░███    ░███  ░███    ░███  ░███  █ ░  ░███  ███  ",
	" ░██████████   ░███████████  ░██████    ░███████   ",
	" ░███░░░░░███  ░███░░░░░███  ░███░░█    ░███░███   ",
	" ░███    ░███  ░███    ░███  ░███ ░   █ ░███ ░░███ ",
	" █████   █████ █████   █████ ██████████ █████ ░░████",
	"░░░░░   ░░░░░ ░░░░░   ░░░░░ ░░░░░░░░░░ ░░░░░   ░░░░ ",
}

local menu = {
	{ "⌕  Find File", "Space f f", function() require("telescope.builtin").find_files() end },
	{ "◷  Recent Files", "Space f b", function() require("telescope.builtin").buffers() end },
	{ "⌕  Find Word", "Space f g", function() require("telescope.builtin").live_grep() end },
	{ "⌘  Help Tags", "Space f h", function() require("telescope.builtin").help_tags() end },
	{ "⌘  Symbols", "Space f s", function() require("telescope.builtin").lsp_document_symbols() end },
}
local rule = "────────────────────────────────────────────"
local content = { "" }
vim.list_extend(content, logo)
vim.list_extend(content, { "", "⚡  Powered by Neovim", "" })
local menu_rows = {}
for _, item in ipairs(menu) do
	local label = item[1]
	local keys = item[2]
	local gap = math.max(2, 38 - vim.fn.strdisplaywidth(label))
	content[#content + 1] = label .. string.rep(" ", gap) .. keys
	menu_rows[#menu_rows + 1] = #content - 1 -- zero-based buffer row
end
vim.list_extend(content, { "", rule, "✦  RAEK NVIM • READY", rule, "" })
local footer_start = #content - 4 -- zero-based row of first rule

local width, height = vim.api.nvim_win_get_width(0), vim.api.nvim_win_get_height(0)
local max_width = 0
for _, line in ipairs(content) do
	max_width = math.max(max_width, vim.fn.strdisplaywidth(line))
end
local lines = {}
for index, line in ipairs(content) do
	local line_width = vim.fn.strdisplaywidth(line)
	local pad
	if index >= 2 and index <= #logo + 1 then
		-- Center each logo row against the actual editor width, independently
		-- of the dashboard menu/footer width.
		pad = math.max(0, math.floor((width - line_width) / 2))
	else
		pad = math.max(0, math.floor((width - max_width) / 2) + math.floor((max_width - line_width) / 2))
	end
	lines[#lines + 1] = string.rep(" ", pad) .. line
end
local top = math.max(0, math.floor((height - #lines) / 2))
for _ = 1, top do
	table.insert(lines, 1, "")
end

local buf = vim.api.nvim_get_current_buf()
vim.bo[buf].buftype = "nofile"
vim.bo[buf].bufhidden = "wipe"
vim.bo[buf].swapfile = false
vim.bo[buf].modifiable = true
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
vim.bo[buf].modifiable = false
vim.bo[buf].filetype = "raek-start"

local ns = vim.api.nvim_create_namespace("raek_start_screen")
local palette = { "#FF6B90", "#EF45B5", "#C246CB", "#875BE4", "#4299FF" }
for i, color in ipairs(palette) do
	vim.api.nvim_set_hl(0, "RaekLogo" .. i, { fg = color })
end
for i = 1, #logo do
	local color = math.min(#palette, math.floor((i - 1) / (#logo - 1) * (#palette - 1)) + 1)
	vim.api.nvim_buf_add_highlight(buf, ns, "RaekLogo" .. color, top + i, 0, -1)
end
vim.api.nvim_buf_add_highlight(buf, ns, "Title", top + #logo + 2, 0, -1)
for _, row in ipairs(menu_rows) do
	vim.api.nvim_buf_add_highlight(buf, ns, "Comment", top + row, 0, -1)
end
vim.api.nvim_buf_add_highlight(buf, ns, "Comment", top + footer_start, 0, -1)
vim.api.nvim_buf_add_highlight(buf, ns, "DiagnosticInfo", top + footer_start + 1, 0, -1)
vim.api.nvim_buf_add_highlight(buf, ns, "Comment", top + footer_start + 2, 0, -1)

vim.opt_local.number = false
vim.opt_local.relativenumber = false
vim.opt_local.cursorline = false
vim.opt_local.signcolumn = "no"
vim.opt_local.wrap = false
vim.opt_local.fillchars:append({ eob = " " })

-- Hide dashboard chrome and restore the user's settings on leaving it.
local win = vim.api.nvim_get_current_win()
local previous_laststatus = vim.o.laststatus
local previous_winhl = vim.wo[win].winhl
vim.o.laststatus = 0
vim.wo[win].winhl = (previous_winhl ~= "" and previous_winhl .. "," or "") .. "Cursor:Normal"
vim.api.nvim_create_autocmd("BufLeave", {
	buffer = buf,
	once = true,
	callback = function()
		vim.o.laststatus = previous_laststatus
		if vim.api.nvim_win_is_valid(win) then
			vim.wo[win].winhl = previous_winhl
		end
	end,
})

local menu_cols = {}
for i, row in ipairs(menu_rows) do
	menu_cols[i] = #(lines[top + row + 1]:match("^ *") or "")
end
local first_menu_row = top + menu_rows[1]
vim.api.nvim_win_set_cursor(win, { first_menu_row + 1, menu_cols[1] })
local function move_menu(step)
	local current = vim.api.nvim_win_get_cursor(win)[1] - 1 - top
	local index = 1
	for i, row in ipairs(menu_rows) do
		if row == current then
			index = i
			break
		end
	end
	index = ((index - 1 + step) % #menu_rows) + 1
	vim.api.nvim_win_set_cursor(win, { top + menu_rows[index] + 1, menu_cols[index] })
end
vim.keymap.set("n", "j", function() move_menu(1) end, { buffer = buf, silent = true })
vim.keymap.set("n", "<Down>", function() move_menu(1) end, { buffer = buf, silent = true })
vim.keymap.set("n", "k", function() move_menu(-1) end, { buffer = buf, silent = true })
vim.keymap.set("n", "<Up>", function() move_menu(-1) end, { buffer = buf, silent = true })
vim.keymap.set("n", "gg", function() vim.api.nvim_win_set_cursor(win, { first_menu_row + 1, menu_cols[1] }) end, { buffer = buf, silent = true })
vim.keymap.set("n", "G", function() vim.api.nvim_win_set_cursor(win, { top + menu_rows[#menu_rows] + 1, menu_cols[#menu_cols] }) end, { buffer = buf, silent = true })
vim.api.nvim_create_autocmd("CursorMoved", {
	buffer = buf,
	callback = function()
		local cursor = vim.api.nvim_win_get_cursor(win)
		local row = cursor[1] - 1 - top
		for _, menu_row in ipairs(menu_rows) do
			if row == menu_row then
				local index = vim.fn.index(menu_rows, menu_row) + 1
				if cursor[2] ~= menu_cols[index] then
					vim.api.nvim_win_set_cursor(win, { top + menu_row + 1, menu_cols[index] })
				end
				return
			end
		end
		local nearest = menu_rows[1]
		for _, menu_row in ipairs(menu_rows) do
			if math.abs(menu_row - row) < math.abs(nearest - row) then
				nearest = menu_row
			end
		end
		local index = vim.fn.index(menu_rows, nearest) + 1
		vim.api.nvim_win_set_cursor(win, { top + nearest + 1, menu_cols[index] })
	end,
})
vim.keymap.set("n", "<CR>", function()
	local row = vim.api.nvim_win_get_cursor(win)[1] - 1 - top
	for i, menu_row in ipairs(menu_rows) do
		if row == menu_row then
			menu[i][3]()
			return
		end
	end
end, { buffer = buf, silent = true, desc = "Open selected RAEK dashboard item" })
