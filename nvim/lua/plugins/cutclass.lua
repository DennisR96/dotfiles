return {
	"gbprod/cutlass.nvim",
	opts = {
		cut_key = "x", -- "x" will now cut (move), while "d" will just delete (void)
		override_del = true, -- optional: makes the <Del> key also void
		exclude = {}, -- optional: if you want normal behavior for some keys
		registers = {
			select = "_", -- default: visual selection goes to blackhole
			delete = "_", -- default: delete goes to blackhole
			change = "_", -- default: change goes to blackhole
		},
	},
}
