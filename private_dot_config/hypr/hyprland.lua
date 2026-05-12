-- Hyprland Lua configuration
-- Hyprland 0.55+ loads this file instead of hyprland.conf.

require("monitors")
require("configs.colors")
require("configs.startup")
require("configs.environment")
require("configs.configuration")
require("configs.input")
require("configs.keybindings")

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
hl.window_rule({ match = { class = "^(footclient)$" }, float = true })
hl.window_rule({ match = { class = "^(footclient)$" }, size = { "monitor_w*0.8", "monitor_h*0.8" } })
hl.window_rule({ match = { class = "^(footclient)$" }, center = true })

hl.window_rule({ match = { class = "^(foot)$", title = "^(fsel)$" }, float = true })
hl.window_rule({ match = { class = "^(foot)$", title = "^(fsel)$" }, size = { "monitor_w*0.3", "monitor_h*0.5" } })
hl.window_rule({ match = { class = "^(foot)$", title = "^(fsel)$" }, center = true })

-- Don't allow idle on fullscreen windows
hl.window_rule({
  name = "windowrule-1",
  match = { class = ".*" },
  idle_inhibit = "fullscreen",
})

-- Ignore maximize requests from apps.
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

-- Fix some dragging issues with XWayland
hl.window_rule({
  match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
  no_focus = true,
})

-- xwaylandvideobridge
hl.window_rule({ match = { class = "^(xwaylandvideobridge)$" }, opacity = "0.0 override 0.0 override" })
hl.window_rule({ match = { class = "^(xwaylandvideobridge)$" }, no_anim = true })
hl.window_rule({ match = { class = "^(xwaylandvideobridge)$" }, no_initial_focus = true })
hl.window_rule({ match = { class = "^(xwaylandvideobridge)$" }, max_size = { 1, 1 } })
hl.window_rule({ match = { class = "^(xwaylandvideobridge)$" }, no_blur = true })

hl.layer_rule({ match = { namespace = "^(waybar)$" }, blur = true })
