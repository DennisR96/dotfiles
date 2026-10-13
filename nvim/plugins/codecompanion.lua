-- CodeCompanion: pi runs as an ACP agent (chat only).
require("codecompanion").setup({
	adapters = {
		acp = {
			pi = function()
				local helpers = require("codecompanion.adapters.acp.helpers")
				return {
					name = "pi",
					formatted_name = "Pi",
					type = "acp",
					roles = { llm = "assistant", user = "user" },
					commands = { default = { "pi-acp" } },
					defaults = { mcpServers = {}, timeout = 20000 },
					parameters = {
						protocolVersion = 1,
						clientCapabilities = { fs = { readTextFile = true, writeTextFile = true } },
						clientInfo = { name = "CodeCompanion.nvim", version = "1.0.0" },
					},
					handlers = {
						setup = function()
							return true
						end,
						form_messages = function(self, messages, capabilities)
							return helpers.form_messages(self, messages, capabilities)
						end,
						on_exit = function() end,
					},
				}
			end,
		},
	},
	interactions = { chat = { adapter = "pi" } },
	display = { chat = { window = { width = 0.4 } } },
})
vim.keymap.set({ "n", "v" }, "<leader>ac", "<cmd>CodeCompanionChat<cr>", { desc = "New Pi chat" })
vim.keymap.set("v", "<leader>aa", "<cmd>CodeCompanionChat Add<cr>", { desc = "Add selection to Pi chat" })
