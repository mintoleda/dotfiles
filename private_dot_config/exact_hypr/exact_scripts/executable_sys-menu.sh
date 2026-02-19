#!/bin/bash

# sys-menu.sh - A wofi-based system menu for Hyprland

# notify-send "DEBUG" "sys-menu.sh script started"
echo "--- sys-menu.sh started at $(date) ---" >>/tmp/sys-menu.log

# Icons or emojis to make it look nice
ICON_PERF="󰓅"
ICON_NOTIF="󰂚"
ICON_ECO=""
ICON_WALL="󰸉"
ICON_SS="󰄀"
ICON_BT="󰂯"
ICON_QS="󱄔"
ICON_UPTIME="󰅐"
ICON_IDLE="󱎫"

# Ensure we are in the wofi directory for relative CSS imports
cd "/home/adetola/.config/wofi" || exit

# Calculate wofi dimensions based on menu content
# Uses 18px SFMono monospace (~11px/char) + ~150px CSS padding
wofi_width() {
    local items="$1"
    local longest=$(echo "$items" | awk '{ if (length > max) max = length } END { print max }')
    echo $((longest * 11 + 150))
}

function main_menu() {
    options=$(
        cat <<EOF
$ICON_PERF Power Mode
$ICON_NOTIF Toggle Notifications
$ICON_ECO Toggle Battery Saver
$ICON_BT Toggle Bluetooth
$ICON_IDLE Toggle Auto-Lock
$ICON_WALL Change Wallpaper
$ICON_SS Screenshot (Region)
$ICON_QS Refresh QuickShell
$ICON_UPTIME System Info
EOF
    )

    # Use the same format as theme_toggle.sh
    choice=$(echo -e "$options" | wofi -dmenu -p "System Menu" --width $(wofi_width "$options") --height 450 --cache-file /dev/null)
    echo "DEBUG: raw choice is '[$choice]'" >>/tmp/sys-menu.log

    case "$choice" in
    *"Power Mode"*)
        perf_menu
        ;;
    *"Toggle Notifications"*)
        makoctl mode | grep -q "do-not-disturb" && makoctl mode -r do-not-disturb || makoctl mode -a do-not-disturb
        notify-send "Notifications" "Toggled DND mode" -i dialog-information
        ;;
    *"Toggle Battery Saver"*)
        # Determine current state from asusctl or animations
        current_profile=$(asusctl profile get | grep "Active profile" | cut -d' ' -f3)
        if [ "$current_profile" == "Quiet" ]; then
            ~/.config/quickshell/lib/toggle-eco.sh off
            notify-send "Battery Saver" "Disabled (Balanced)" -i dialog-information
        else
            ~/.config/quickshell/lib/toggle-eco.sh on
            notify-send "Battery Saver" "Enabled (Quiet)" -i dialog-information
        fi
        ;;
    *"Toggle Bluetooth"*)
        if bluetoothctl show | grep -q "Powered: yes"; then
            bluetoothctl power off
            notify-send "Bluetooth" "Powered Off" -i bluetooth
        else
            bluetoothctl power on
            notify-send "Bluetooth" "Powered On" -i bluetooth
        fi
        ;;
    *"Toggle Auto-Lock"*)
        echo "MATCHED: Toggle Auto-Lock" >>/tmp/sys-menu.log
        if systemctl --user is-active --quiet hypridle; then
            systemctl --user stop hypridle
            notify-send "Auto-Lock" "Auto-lock DISABLED"
        else
            systemctl --user start hypridle
            notify-send "Auto-Lock" "Auto-lock ENABLED"
        fi
        ;;
    *"Change Wallpaper"*)
        waypaper
        ;;
    *"Screenshot (Region)")
        hyprshot -m region
        ;;
    *"Refresh QuickShell")
        pkill quickshell
        quickshell &
        notify-send "QuickShell" "Restarted" -i dialog-information
        ;;
    *"System Info")
        uptime_p=$(uptime -p)
        bat_cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1)
        bat_stat=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1)
        notify-send "System Information" "Uptime: $uptime_p
Battery: $bat_cap% ($bat_stat)" -i dialog-information
        ;;
    *)
        if [[ -n "$choice" ]]; then
            echo "DEBUG: unrecognized choice '[$choice]'" >>/tmp/sys-menu.log
        fi
        ;;
    esac
}

function perf_menu() {
    perf_options=$(
        cat <<EOF
Quiet (Power Saver)
Balanced (Standard)
Performance (High Power)
EOF
    )

    perf_choice=$(echo -e "$perf_options" | wofi -dmenu -p "Select Performance Profile" --width $(wofi_width "$perf_options") --height 300 --cache-file /dev/null)

    case "$perf_choice" in
    "Quiet"*)
        asusctl profile set Quiet
        notify-send "Performance" "Switched to Quiet profile" -i speedmeter-low
        ;;
    "Balanced"*)
        asusctl profile set Balanced
        notify-send "Performance" "Switched to Balanced profile" -i speedmeter-middle
        ;;
    "Performance"*)
        asusctl profile set Performance
        notify-send "Performance" "Switched to Performance profile" -i speedmeter-high
        ;;
    esac
}

main_menu
