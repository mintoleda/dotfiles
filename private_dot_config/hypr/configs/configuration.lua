-- Configuration/Styling for Hyprland

local function border_color(value)
  local first, second, angle = value:match("^(rgba%([^)]+%))%s+(rgba%([^)]+%))%s+(%d+)deg$")
  if first and second and angle then
    return { colors = { first, second }, angle = tonumber(angle) }
  end
  return value
end

hl.config({
  general = {
    border_size = 0,
    col = {
      active_border = border_color(activeBorder),
      inactive_border = border_color(inactiveBorder),
    },
    gaps_in = 1,
    gaps_out = 0,
    resize_on_border = true,
  },

  -- xwayland = {
  --   force_zero_scaling = true,
  -- },

  cursor = {
    no_hardware_cursors = true,
  },

  decoration = {
    rounding = 10,
    active_opacity = 0.9,
    inactive_opacity = 0.8,
    shadow = {
      range = 32,
      render_power = 2,
      color = "rgba(1a1a1aee)",
    },
    blur = {
      passes = 5,
      vibrancy = 0.5,
    },
  },

  dwindle = {
    preserve_split = true,
  },

  master = {
    new_status = "master",
  },

  misc = {
    force_default_wallpaper = 1,
    disable_hyprland_logo = true,
    disable_autoreload = true,
  },

  input = {
    touchpad = {
      natural_scroll = true,
      scroll_factor = 0.4,
      middle_button_emulation = true,
    },
  },

  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.config({ animations = { enabled = true } })

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
