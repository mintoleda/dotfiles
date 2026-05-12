-- Startup

hl.on("hyprland.start", function()
  -- hl.exec_cmd("waybar")
  -- hl.exec_cmd("quickshell")

  -- Notifications
  hl.exec_cmd("mako --max-history 50")

  hl.exec_cmd("swww-daemon")
  hl.exec_cmd("copyq")
  hl.exec_cmd("foot --server")
  hl.exec_cmd("rog-control-center")

  -- Idle management (direct process, not systemd)
  hl.exec_cmd("~/.config/hypr/scripts/idle.sh start")

  -- Wallpaper utils
  hl.exec_cmd("wallutils & waypaper --restore & wal -R -n")
end)
