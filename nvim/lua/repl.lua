-- Function: WeztermID
_G.WEZTERM_PANE_ID = 1

vim.api.nvim_create_user_command("WeztermID", function(opts)
	_G.WEZTERM_PANE_ID = tonumber(opts.args)
	print("✅ WezTerm pane ID set to: " .. _G.WEZTERM_PANE_ID)
end, { nargs = 1 })

-- Function: Get Visual Selection
function visual_selection()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local lines = vim.fn.getline(start_pos[2], end_pos[2])
	return lines
end

-- 🔹 Escape function (for double quotes and backslashes)
local function escape_line(line)
	return line:gsub("\\", "\\\\"):gsub('"', '\\"')
end

-- 🔹 Send visual selection
function send_selection()
	local lines = visual_selection()

	for i, line in ipairs(lines) do
		lines[i] = escape_line(line)
	end
	local block = table.concat(lines, "\n") .. "\n\n"

	-- Clear terminal and send block
	vim.fn.system("wezterm cli send-text --no-paste --pane-id " .. _G.WEZTERM_PANE_ID .. ' "clear\n"')
	vim.fn.system("wezterm cli send-text --no-paste --pane-id " .. _G.WEZTERM_PANE_ID .. ' "' .. block .. '"')
end

-- 🔹 Send block based on # %%
function send_block()
	local cursor_line = vim.fn.line(".")
	local total_lines = vim.fn.line("$")
	local start_line = cursor_line
	local end_line = cursor_line
	local lines = vim.fn.getline(1, total_lines)

	-- Find start of block
	for i = cursor_line, 1, -1 do
		if lines[i]:match("^# %%%%") then
			start_line = i + 1
			break
		end
	end

	-- Find end of block
	for i = cursor_line + 1, total_lines do
		if lines[i]:match("^# %%%%") then
			end_line = i - 1
			break
		end
	end

	local block_lines = vim.fn.getline(start_line, end_line)
	for i, line in ipairs(block_lines) do
		block_lines[i] = escape_line(line)
	end
	local block = table.concat(block_lines, "\n") .. "\n\n"

	-- Clear terminal and send block
	vim.fn.system("wezterm cli send-text --no-paste --pane-id " .. _G.WEZTERM_PANE_ID .. ' "clear\n"')
	vim.fn.system("wezterm cli send-text --no-paste --pane-id " .. _G.WEZTERM_PANE_ID .. ' "' .. block .. '"')
end

-- 🔹 Commands & Keymaps
vim.api.nvim_create_user_command("WEZSENDSELECTION", send_selection, {})
vim.api.nvim_create_user_command("WEZSENDBLOCK", send_block, {})
