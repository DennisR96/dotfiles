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
local logo_display_width = 0
for _, line in ipairs(logo) do
	logo_display_width = math.max(logo_display_width, vim.fn.strdisplaywidth(line))
end
local logo_pad = math.max(0, math.floor((width - logo_display_width) / 2))
local lines = {}
for index, line in ipairs(content) do
	local pad
	if index >= 2 and index <= #logo + 1 then
		-- Center the whole logo, not each row: Pi keeps every row left-aligned.
		pad = logo_pad
	else
		local line_width = vim.fn.strdisplaywidth(line)
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
local rgb_palette = {}
for i, color in ipairs(palette) do
	rgb_palette[i] = {
		tonumber(color:sub(2, 3), 16),
		tonumber(color:sub(4, 5), 16),
		tonumber(color:sub(6, 7), 16),
	}
end

local function gradient_color(position, phase)
	local scaled = position * (#rgb_palette - 1)
	local index = math.min(math.floor(scaled) + 1, #rgb_palette - 1)
	local fraction = scaled - (index - 1)
	local wave = (1 + math.cos(2 * math.pi * (position * 1.25 - phase))) / 2
	local glow = 0.24 * wave * wave * wave
	local channels = {}
	for channel = 1, 3 do
		local start, finish = rgb_palette[index][channel], rgb_palette[index + 1][channel]
		local base = math.floor(start + (finish - start) * fraction + 0.5)
		channels[channel] = math.floor(base + (255 - base) * glow + 0.5)
	end
	return string.format("#%02X%02X%02X", channels[1], channels[2], channels[3])
end

local logo_ns = vim.api.nvim_create_namespace("raek_start_screen_logo")
local logo_width = 0
for _, line in ipairs(logo) do
	logo_width = math.max(logo_width, vim.fn.strchars(line))
end
local logo_columns = {}
for row, line in ipairs(logo) do
	-- Extmark columns are byte offsets into the *centered* buffer line.
	local byte_col = #(lines[top + row + 1]:match("^ *") or "") - #(line:match("^ *") or "")
	for char_index = 0, vim.fn.strchars(line) - 1 do
		local char = vim.fn.strcharpart(line, char_index, 1)
		local byte_end = byte_col + #char
		if char ~= " " then
			local group = "RaekLogoAnim" .. char_index
			logo_columns[char_index] = true
			vim.api.nvim_buf_set_extmark(buf, logo_ns, top + row, byte_col, {
				end_col = byte_end,
				hl_group = group,
			})
		end
		byte_col = byte_end
	end
end

local started_at = vim.uv.hrtime()
local animation = vim.uv.new_timer()
local function render_logo()
	if not vim.api.nvim_buf_is_valid(buf) then
		animation:stop()
		animation:close()
		return
	end
	local phase = ((vim.uv.hrtime() - started_at) / 1e6 / 4500) % 1
	for char_index in pairs(logo_columns) do
		local position = logo_width > 1 and char_index / (logo_width - 1) or 0
		vim.api.nvim_set_hl(0, "RaekLogoAnim" .. char_index, { fg = gradient_color(position, phase) })
	end
end
render_logo()
animation:start(33, 33, vim.schedule_wrap(render_logo))
vim.api.nvim_create_autocmd("BufWipeout", {
	buffer = buf,
	once = true,
	callback = function()
		if not animation:is_closing() then
			animation:stop()
			animation:close()
		end
	end,
})
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
