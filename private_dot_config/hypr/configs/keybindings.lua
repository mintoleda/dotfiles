-- Aliases
local mainMod = "SUPER"

local terminal = "footclient"
local fileManager = "thunar"
local denu = "foot -T fsel fsel --detach"
local browser = "zen-browser"
local lockScreen = "hyprlock"
local ssUtil = "hyprshot -m region"
local copyUtil = "copyq"
local bar = "waybar"
local hyprScripts = "/home/adetola/.config/hypr/scripts"

local function dispatch(command)
  return hl.dsp.exec_cmd("hyprctl dispatch " .. command)
end

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser), { release = true })
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(lockScreen))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("pgrep -x " .. bar .. " && pkill " .. bar .. " || " .. bar .. " &"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(denu))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(hyprScripts .. "/sys-menu.sh"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(hyprScripts .. "/theme_toggle.sh"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(ssUtil))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(copyUtil .. " toggle"))
hl.bind("CTRL + ALT + R", hl.dsp.exec_cmd("pkill " .. bar .. " && " .. bar .. " &"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("bash " .. hyprScripts .. "/sys-menu.sh"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", dispatch("exit"))

hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SHIFT + F11", dispatch("fullscreen"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Switch/move workspaces with mainMod + [0-9]
for i = 1, 10 do
  local key = tostring(i % 10)
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
  hl.bind(mainMod .. " + ALT + " .. key, dispatch("movetoworkspacesilent " .. i))
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(hyprScripts .. "/volume_brightness.sh vol_up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(hyprScripts .. "/volume_brightness.sh vol_down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(hyprScripts .. "/volume_brightness.sh vol_mute"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(hyprScripts .. "/volume_brightness.sh br_up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(hyprScripts .. "/volume_brightness.sh br_down"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
