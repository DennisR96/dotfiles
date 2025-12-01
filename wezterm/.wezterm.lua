local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font_size = 16
config.initial_cols = 140
config.initial_rows = 40
config.send_composed_key_when_left_alt_is_pressed = true
-- config.window_decorations = "TITLE | RESIZE"
config.window_decorations = "RESIZE"
config.window_padding = {
	left = 50,
	right = 50,
	top = 25,
	bottom = 0,
}
-- Theme
config.color_scheme = "Catppuccin Frappe"
config.max_fps = 120

-- Tab Bar
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.window_background_opacity = 0.9
config.macos_window_background_blur = 50

return config
