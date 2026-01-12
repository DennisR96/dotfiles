return {
	"stevearc/oil.nvim",
	dependencies = { { "nvim-mini/mini.icons", opts = {} } },
	lazy = false,
	opts = {
		delete_to_trash = true,
		keymaps = {
			-- Existing single file copy
			["<leader>cc"] = {
				desc = "Copy file content to system clipboard with Markdown header",
				callback = function()
					local oil = require("oil")
					local entry = oil.get_cursor_entry()
					local dir = oil.get_current_dir()

					if not entry or not dir then
						return
					end

					if entry.type == "file" then
						local full_path = dir .. entry.name
						local file = io.open(full_path, "r")

						if file then
							local content = file:read("*a")
							file:close()
							local text_to_copy = "# " .. entry.name .. "\n" .. content
							vim.fn.setreg("+", text_to_copy)
							vim.notify("Copied " .. entry.name .. " to clipboard")
						else
							vim.notify("Could not open file", vim.log.levels.ERROR)
						end
					else
						vim.notify("Cannot copy content of a directory", vim.log.levels.WARN)
					end
				end,
			},
			-- New: Copy all files in directory recursively
			["<leader>cb"] = {
				desc = "Copy all files in dir (recursive) to clipboard",
				callback = function()
					local oil = require("oil")
					local root_dir = oil.get_current_dir()
					local uv = vim.uv or vim.loop

					if not root_dir then
						return
					end

					-- Configure ignore patterns here
					local ignored_names = {
						[".git"] = true,
						["node_modules"] = true,
						["__pycache__"] = true,
						[".DS_Store"] = true,
						["target"] = true,
						["build"] = true,
						["dist"] = true,
					}

					-- Check for binary extensions to skip
					local function is_binary(filename)
						local ext = filename:match("^.+(%..+)$")
						local binary_ext = {
							[".png"] = true,
							[".jpg"] = true,
							[".jpeg"] = true,
							[".gif"] = true,
							[".webp"] = true,
							[".ico"] = true,
							[".pdf"] = true,
							[".zip"] = true,
							[".tar"] = true,
							[".gz"] = true,
							[".7z"] = true,
							[".rar"] = true,
							[".exe"] = true,
							[".dll"] = true,
							[".so"] = true,
							[".o"] = true,
							[".pyc"] = true,
							[".class"] = true,
						}
						return ext and binary_ext[ext]
					end

					local file_contents = {}
					local file_list = {}

					-- Recursive walker
					local function traverse(current_dir)
						local handle = uv.fs_scandir(current_dir)
						if not handle then
							return
						end

						while true do
							local name, type = uv.fs_scandir_next(handle)
							if not name then
								break
							end

							if not ignored_names[name] then
								local full_path = current_dir .. name
								local relative_path = full_path:sub(#root_dir + 1)

								if type == "directory" then
									traverse(full_path .. "/")
								elseif type == "file" and not is_binary(name) then
									local f = io.open(full_path, "r")
									if f then
										local content = f:read("*a")
										f:close()
										table.insert(file_list, "- " .. relative_path)
										table.insert(file_contents, "## " .. relative_path .. "\n\n" .. content)
									end
								end
							end
						end
					end

					vim.notify("Scanning directory...", vim.log.levels.INFO)
					traverse(root_dir)

					if #file_contents > 0 then
						local tree_view = "# Directory Structure\n\n" .. table.concat(file_list, "\n") .. "\n\n"
						local full_output = tree_view .. table.concat(file_contents, "\n\n")

						vim.fn.setreg("+", full_output)
						vim.notify("Copied " .. #file_contents .. " files to clipboard")
					else
						vim.notify("No valid files found to copy", vim.log.levels.WARN)
					end
				end,
			},
		},
	},
}
