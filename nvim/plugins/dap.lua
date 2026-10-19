local dap = require("dap")

local function fail(message)
	vim.notify(message, vim.log.levels.ERROR)
	error(message)
end

local selected_buffer
local selected_project

local function project_file()
	local path = vim.api.nvim_buf_get_name(0)
	if path == selected_buffer and selected_project then
		return selected_project
	end
	selected_buffer = path
	local dir = path ~= "" and vim.fs.dirname(path) or vim.fn.getcwd()

	while dir do
		local projects = {}
		for name, kind in vim.fs.dir(dir) do
			if kind == "file" and name:match("%.csproj$") then
				projects[#projects + 1] = vim.fs.joinpath(dir, name)
			end
		end
		table.sort(projects)
		if #projects == 1 then
			selected_project = projects[1]
			return selected_project
		elseif #projects > 1 then
			local choices = { "Select the .NET project to debug:" }
			for _, project in ipairs(projects) do
				choices[#choices + 1] = vim.fn.fnamemodify(project, ":t")
			end
			local choice = vim.fn.inputlist(choices)
			if choice < 1 or choice > #projects then
				fail("No .NET project selected")
			end
			selected_project = projects[choice]
			return selected_project
		end
		dir = vim.fs.dirname(dir)
	end

	fail("No .csproj found in the current file's parent directories")
end

local function run(command, cwd)
	local result = vim.system(command, { cwd = cwd, text = true }):wait()
	if result.code ~= 0 then
		fail((result.stderr or result.stdout or "Command failed: " .. table.concat(command, " ")):gsub("%s+$", ""))
	end
	return (result.stdout or ""):gsub("%s+$", "")
end

local function project_output()
	local project = project_file()
	local cwd = vim.fs.dirname(project)
	local properties = run({ "dotnet", "msbuild", project, "-getProperty:TargetFrameworks" }, cwd)
	local frameworks = {}
	for framework in properties:gmatch("[^;]+") do
		framework = vim.trim(framework)
		if framework ~= "" then
			frameworks[#frameworks + 1] = framework
		end
	end
	if #frameworks == 0 then
		local framework = run({ "dotnet", "msbuild", project, "-getProperty:TargetFramework" }, cwd)
		if framework ~= "" then
			frameworks[1] = framework
		end
	end
	if #frameworks == 0 then
		fail("Could not determine the project's target framework")
	end
	local framework = frameworks[1]
	if #frameworks > 1 then
		local choices = { "Select the target framework to debug:" }
		vim.list_extend(choices, frameworks)
		local choice = vim.fn.inputlist(choices)
		if choice < 1 or choice > #frameworks then
			fail("No target framework selected")
		end
		framework = frameworks[choice]
	end

	run({ "dotnet", "build", project, "--configuration", "Debug", "--framework", framework, "--nologo" }, cwd)
	local output = run({
		"dotnet", "msbuild", project,
		"-getProperty:TargetPath",
		"-property:Configuration=Debug",
		"-property:TargetFramework=" .. framework,
	}, cwd)
	if output == "" then
		fail("MSBuild did not report the project's output path")
	end
	output = vim.fn.fnamemodify(output, ":p")
	return output, cwd
end

local netcoredbg = "netcoredbg"
if vim.fn.has("macunix") == 1 and vim.uv.os_uname().machine == "arm64" then
	-- Mason's macOS netcoredbg is x86_64 and cannot debug an arm64 .NET process.
	netcoredbg = vim.api.nvim_get_runtime_file("netcoredbg/netcoredbg", false)[1]
	if not netcoredbg or vim.fn.executable(netcoredbg) ~= 1 then
		fail("Native arm64 netcoredbg not found. Install Cliffback/netcoredbg-macOS-arm64.nvim.")
	end
elseif vim.fn.executable(netcoredbg) ~= 1 then
	local mason_netcoredbg = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin", "netcoredbg")
	if vim.fn.executable(mason_netcoredbg) == 1 then
		netcoredbg = mason_netcoredbg
	else
		vim.notify("netcoredbg not found. Install it with :Mason or add it to PATH.", vim.log.levels.ERROR)
	end
end

dap.adapters.coreclr = {
	type = "executable",
	command = netcoredbg,
	args = { "--interpreter=vscode" },
}

dap.configurations.cs = {
	{
		name = "Launch current .NET project",
		type = "coreclr",
		request = "launch",
		stopAtEntry = true,
		program = project_output,
		cwd = function()
			return vim.fs.dirname(project_file())
		end,
	},
}

vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: continue" })
vim.keymap.set("n", "<leader>dr", dap.repl.toggle, { desc = "Debug: toggle REPL" })
vim.keymap.set("n", "<leader>dc", dap.run_to_cursor, { desc = "Debug: run to cursor" })
vim.keymap.set("n", "<leader>dq", dap.terminate, { desc = "Debug: terminate" })
vim.keymap.set({ "n", "v" }, "<leader>dh", function()
	require("dap.ui.widgets").hover()
end, { desc = "Debug: inspect variable" })
vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "Debug: toggle breakpoint" })
vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: step over" })
vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: step into" })
vim.keymap.set("n", "<S-F11>", dap.step_out, { desc = "Debug: step out" })
