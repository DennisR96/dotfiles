local wezterm = require("wezterm")
local config = wezterm.config_builder()

config = {
	font_size = 16,
	initial_cols = 150,
	initial_rows = 60,
	send_composed_key_when_left_alt_is_pressed = true,
	window_decorations = "TITLE | RESIZE",
	window_padding = {
		left = 20,
		right = 0,
		top = 0,
		bottom = 0,
	},
	-- Theme
	color_scheme = "Catppuccin Frappe",
	max_fps = 120,

	-- Tab Bar
	enable_tab_bar = true,
	use_fancy_tab_bar = false,
	tab_bar_at_bottom = true,
	window_background_opacity = 0.92,
	macos_window_background_blur = 50,
}
return config
