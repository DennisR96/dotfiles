-- CodeDiff
require("codediff").setup()

-- Diff navigation.
vim.keymap.set("n", "<leader>dp", "[c", { desc = "Previous diff change" })
vim.keymap.set("n", "<leader>dn", "]c", { desc = "Next diff change" })
vim.keymap.set("n", "<leader>dv", "<cmd>CodeDiff<cr>", { desc = "Open CodeDiff" })
