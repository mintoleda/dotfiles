#!/bin/bash

# sys-menu.sh - A wofi-based system menu for Hyprland with frecency sorting

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "/home/adetola/.config/wofi" || exit

FRECENCY_DIR="$HOME/.cache/sys-menu"
FRECENCY_FILE="$FRECENCY_DIR/frecency.tsv"

# Parallel arrays — filled by build_menu_items, reordered by sort_items_by_frecency
ITEM_KEYS=()
ITEM_LABELS=()

# Toggle states — set once by detect_states
STATE_DND=0
STATE_BATTERY_SAVER=0
STATE_BLUETOOTH=0
STATE_IDLE=0

# Associative arrays for frecency data
declare -A FREQ_COUNT
declare -A FREQ_LAST

# --- Utility ---

wofi_width() {
    local items="$1"
    local longest
    longest=$(echo "$items" | awk '{ if (length > max) max = length } END { print max }')
    echo $((longest * 11 + 150))
}

# --- State Detection ---

detect_states() {
    if makoctl mode | grep -q "do-not-disturb"; then
        STATE_DND=1
    fi

    local profile
    profile=$(asusctl profile get 2>/dev/null | grep "Active profile" | cut -d' ' -f3)
    if [ "$profile" = "Quiet" ]; then
        STATE_BATTERY_SAVER=1
    fi

    if bluetoothctl show | grep -q "Powered: yes"; then
        STATE_BLUETOOTH=1
    fi

    if pgrep -x hypridle >/dev/null; then
        STATE_IDLE=1
    fi
}

# --- Menu Construction ---

build_menu_items() {
    local notif_label bt_label battery_label idle_label

    if [ "$STATE_DND" -eq 1 ]; then
        notif_label="Turn notifications on"
    else
        notif_label="Turn notifications off"
    fi

    if [ "$STATE_BATTERY_SAVER" -eq 1 ]; then
        battery_label="Turn battery saver off"
    else
        battery_label="Turn battery saver on"
    fi

    if [ "$STATE_BLUETOOTH" -eq 1 ]; then
        bt_label="Turn bluetooth off"
    else
        bt_label="Turn bluetooth on"
    fi

    if [ "$STATE_IDLE" -eq 1 ]; then
        idle_label="Turn idle-daemon off"
    else
        idle_label="Turn idle-daemon on"
    fi

    ITEM_KEYS=(power_mode notifications battery_saver bluetooth idle_daemon wallpaper screenshot waybar sysinfo)
    ITEM_LABELS=("Power Mode" "$notif_label" "$battery_label" "$bt_label" "$idle_label" "Change Wallpaper" "Screenshot (Region)" "Refresh Waybar" "System Info")
}

# --- Frecency ---

frecency_load() {
    if [ ! -f "$FRECENCY_FILE" ]; then
        return
    fi
    while IFS=$'\t' read -r key count ts; do
        FREQ_COUNT["$key"]=$count
        FREQ_LAST["$key"]=$ts
    done <"$FRECENCY_FILE"
}

frecency_score() {
    local key="$1"
    local count=${FREQ_COUNT["$key"]:-0}
    local last=${FREQ_LAST["$key"]:-0}

    if [ "$count" -eq 0 ]; then
        echo 0
        return
    fi

    local now
    now=$(date +%s)
    local age=$((now - last))
    local weight

    if [ "$age" -lt 3600 ]; then
        weight=400
    elif [ "$age" -lt 86400 ]; then
        weight=200
    elif [ "$age" -lt 604800 ]; then
        weight=100
    elif [ "$age" -lt 2592000 ]; then
        weight=50
    else
        weight=25
    fi

    echo $((count * weight))
}

sort_items_by_frecency() {
    local n=${#ITEM_KEYS[@]}
    # Build index-score pairs
    local indices=()
    local scores=()
    for ((i = 0; i < n; i++)); do
        indices+=("$i")
        scores+=("$(frecency_score "${ITEM_KEYS[$i]}")")
    done

    # Stable insertion sort by score descending
    for ((i = 1; i < n; i++)); do
        local j=$i
        while [ "$j" -gt 0 ] && [ "${scores[$j]}" -gt "${scores[$((j - 1))]}" ]; do
            # Swap scores
            local tmp="${scores[$j]}"
            scores[$j]="${scores[$((j - 1))]}"
            scores[$((j - 1))]="$tmp"
            # Swap indices
            tmp="${indices[$j]}"
            indices[$j]="${indices[$((j - 1))]}"
            indices[$((j - 1))]="$tmp"
            ((j--))
        done
    done

    # Rebuild arrays in sorted order
    local sorted_keys=()
    local sorted_labels=()
    for ((i = 0; i < n; i++)); do
        local idx="${indices[$i]}"
        sorted_keys+=("${ITEM_KEYS[$idx]}")
        sorted_labels+=("${ITEM_LABELS[$idx]}")
    done
    ITEM_KEYS=("${sorted_keys[@]}")
    ITEM_LABELS=("${sorted_labels[@]}")
}

# --- Wofi ---

show_wofi_menu() {
    local menu=""
    for label in "${ITEM_LABELS[@]}"; do
        if [ -n "$menu" ]; then
            menu+=$'\n'
        fi
        menu+="$label"
    done

    echo "$menu" | wofi -dmenu -p "System Menu" --width "$(wofi_width "$menu")" --height 450 --cache-file /dev/null --no-cache
}

label_to_key() {
    local selection
    selection=$(echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    for ((i = 0; i < ${#ITEM_LABELS[@]}; i++)); do
        if [ "${ITEM_LABELS[$i]}" = "$selection" ]; then
            echo "${ITEM_KEYS[$i]}"
            return
        fi
    done
}

# --- Actions ---

execute_action() {
    local key="$1"
    case "$key" in
    power_mode)
        perf_menu
        ;;
    notifications)
        if [ "$STATE_DND" -eq 1 ]; then
            makoctl mode -r do-not-disturb
            notify-send "Notifications" "Notifications on" -i dialog-information
        else
            notify-send "Notifications" "Notifications off (DND)" -i dialog-information
            sleep 0.5
            makoctl mode -a do-not-disturb
        fi
        ;;
    battery_saver)
        if [ "$STATE_BATTERY_SAVER" -eq 1 ]; then
            "$SCRIPT_DIR/toggle_eco.sh" off
            notify-send "Battery Saver" "Battery saver off" -i dialog-information
        else
            "$SCRIPT_DIR/toggle_eco.sh" on
            notify-send "Battery Saver" "Battery saver on" -i dialog-information
        fi
        ;;
    bluetooth)
        if [ "$STATE_BLUETOOTH" -eq 1 ]; then
            bluetoothctl power off
            notify-send "Bluetooth" "Bluetooth off" -i bluetooth
        else
            bluetoothctl power on
            notify-send "Bluetooth" "Bluetooth on" -i bluetooth
        fi
        ;;
    idle_daemon)
        "$SCRIPT_DIR/idle.sh" toggle
        ;;
    wallpaper)
        waypaper
        ;;
    screenshot)
        hyprshot -m region
        ;;
    waybar)
        pkill waybar
        waybar &
        notify-send "Waybar" "Restarted" -i dialog-information
        ;;
    sysinfo)
        local uptime_p bat_cap bat_stat
        uptime_p=$(uptime -p)
        bat_cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1)
        bat_stat=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1)
        notify-send "System Information" "Uptime: $uptime_p
Battery: $bat_cap% ($bat_stat)" -i dialog-information
        ;;
    esac
}

frecency_update() {
    local key="$1"
    [ -z "$key" ] && return

    mkdir -p "$FRECENCY_DIR"

    local now
    now=$(date +%s)
    local old_count=${FREQ_COUNT["$key"]:-0}
    FREQ_COUNT["$key"]=$((old_count + 1))
    FREQ_LAST["$key"]=$now

    local tmp
    tmp=$(mktemp "$FRECENCY_DIR/frecency.XXXXXX")
    for k in "${!FREQ_COUNT[@]}"; do
        printf '%s\t%s\t%s\n' "$k" "${FREQ_COUNT[$k]}" "${FREQ_LAST[$k]}" >>"$tmp"
    done
    mv "$tmp" "$FRECENCY_FILE"
}

# --- Submenu ---

perf_menu() {
    local perf_options
    perf_options=$(cat <<EOF
Quiet (Power Saver)
Balanced (Standard)
Performance (High Power)
EOF
    )

    local perf_choice
    perf_choice=$(echo "$perf_options" | wofi -dmenu -p "Select Performance Profile" --width "$(wofi_width "$perf_options")" --height 300 --cache-file /dev/null --no-cache)

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

# --- Main ---

main() {
    detect_states
    build_menu_items
    frecency_load
    sort_items_by_frecency

    local selection
    selection=$(show_wofi_menu)
    [ -z "$selection" ] && exit 0

    local key
    key=$(label_to_key "$selection")
    [ -z "$key" ] && exit 0

    execute_action "$key"
    frecency_update "$key"
}

main
