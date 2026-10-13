-- Oil
require("mini.icons").setup()
-- Telescope reads the nvim-web-devicons API for file icons; use mini.icons as its provider.
require("mini.icons").mock_nvim_web_devicons()
require("oil").setup({
	delete_to_trash = true,
	columns = { "icon" },
	view_options = { show_hidden = true },
})
local size_ns = vim.api.nvim_create_namespace("oil_file_sizes")
local size_generation = {}
local function format_size(size)
	if size < 0 then
		return nil
	elseif size >= 1e9 then
		return string.format("%.1fG", size / 1e9)
	elseif size >= 1e6 then
		return string.format("%.1fM", size / 1e6)
	elseif size >= 1e3 then
		return string.format("%.1fK", size / 1e3)
	else
		return tostring(size)
	end
end
local function show_file_sizes(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= "oil" then
		return
	end
	local oil = require("oil")
	local dir = oil.get_current_dir(bufnr)
	if not dir then
		return
	end
	size_generation[bufnr] = (size_generation[bufnr] or 0) + 1
	local generation = size_generation[bufnr]
	vim.api.nvim_buf_clear_namespace(bufnr, size_ns, 0, -1)
	for lnum = 1, vim.api.nvim_buf_line_count(bufnr) do
		local entry = oil.get_entry_on_line(bufnr, lnum)
		if entry and entry.type == "file" then
			local row, path = lnum - 1, dir .. entry.name
			vim.uv.fs_stat(path, function(err, stat)
				if err or not stat then
					return
				end
				vim.schedule(function()
					if
						not vim.api.nvim_buf_is_valid(bufnr)
						or size_generation[bufnr] ~= generation
						or oil.get_current_dir(bufnr) ~= dir
					then
						return
					end
					local size = format_size(stat.size)
					if size then
						vim.api.nvim_buf_set_extmark(bufnr, size_ns, row, 0, {
							virt_text = { { "  " .. size, "Comment" } },
							virt_text_pos = "eol",
						})
					end
				end)
			end)
		end
	end
end
local function schedule_file_sizes(bufnr)
	vim.schedule(function()
		show_file_sizes(bufnr)
	end)
end
vim.api.nvim_create_autocmd("User", {
	pattern = "OilEnter",
	callback = function(args)
		schedule_file_sizes(args.data and args.data.buf or 0)
	end,
})
vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged" }, {
	callback = function(args)
		if vim.bo[args.buf].filetype == "oil" then
			schedule_file_sizes(args.buf)
		end
	end,
})

-- Copy selected Oil file contents to the clipboard.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "oil",
	callback = function()
		vim.keymap.set("v", "gy", function()
			local oil = require("oil")
			local dir = oil.get_current_dir()
			if not dir then
				return
			end
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
			vim.schedule(function()
				local start_line, end_line = vim.fn.getpos("'<")[2], vim.fn.getpos("'>")[2]
				local bufnr, paths = vim.api.nvim_get_current_buf(), {}
				for i = start_line, end_line do
					local entry = oil.get_entry_on_line(bufnr, i)
					if entry and entry.type == "file" then
						paths[#paths + 1] = dir .. entry.name
					end
				end
				if #paths == 0 then
					return
				end
				local script = [[import pathlib, sys
for name in sys.argv[1:]:
    path = pathlib.Path(name)
    print(f"### {path.name}")
    try:
        print(path.read_text(), end="\n")
    except (UnicodeError, OSError) as error:
        print(f"[Could not read file: {error}]")
    print()]]
				vim.system({ "python3", "-c", script, unpack(paths) }, { text = true }, function(result)
					vim.schedule(function()
						if result.code ~= 0 then
							vim.notify(result.stderr or "Failed to read selected files", vim.log.levels.ERROR)
							return
						end
						vim.fn.setreg("+", result.stdout or "")
						vim.notify("Yanked contents of selected files to clipboard")
					end)
				end)
			end)
		end, { buffer = true, desc = "Yank file contents to clipboard" })
	end,
})
