local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font_size = 16
config.initial_cols = 150
config.initial_rows = 60
config.send_composed_key_when_left_alt_is_pressed = true
config.window_decorations = "TITLE | RESIZE"
config.window_padding = {
  left = 20,
  right = 0,
  top = 0,
  bottom = 0,
}
-- Theme
config.color_scheme = "Catppuccin Frappe"
config.max_fps = 120


-- Tab Bar
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.window_background_opacity = 0.92
config.macos_window_background_blur = 50

return config
