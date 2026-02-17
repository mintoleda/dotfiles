#!/usr/bin/env bash

# --- PATHS ---
THEME_DIR="$HOME/.config/hypr/themes"
HYPR_CONFIG_DIR="$HOME/.config/hypr/configs"
HYPR_COLORS_LINK="$HYPR_CONFIG_DIR/colors.conf"
QS_THEME_LINK="$HOME/.config/quickshell/Colors.qml"
PYWAL_HYPR_CACHE="$HOME/.cache/wal/colors-hyprland.conf"
PYWAL_QS_CACHE="$HOME/.cache/wal/colors.qml"
PYWAL_WOFI_CACHE="$HOME/.cache/wal/colors-waybar.css"
WOFI_COLORS_LINK="$HOME/.config/wofi/colors.css"

# --- FUNCTIONS ---


apply_pywal() {
    notify-send "Theme" "Switching to Pywal..."

    # Link Pywal generated files
    ln -sf "$PYWAL_HYPR_CACHE" "$HYPR_COLORS_LINK"
    ln -sf "$PYWAL_QS_CACHE" "$QS_THEME_LINK"
    ln -sf "$PYWAL_WOFI_CACHE" "$WOFI_COLORS_LINK"

    reload_env
}

apply_static() {
    local theme_name="$1"
    local theme_path="$THEME_DIR/$theme_name"

    notify-send "Theme" "Switching to $theme_name..."

    # Set Wallpaper
    local wallpaper=$(find "$theme_path" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" \) -print -quit)
    if [[ -n "$wallpaper" ]]; then
        waypaper --wallpaper "$wallpaper"
        wal -i "$wallpaper" -n --cols16
    else
        notify-send "Theme Warning" "No wallpaper found in $theme_name"
    fi

    # Link Pywal generated files
    ln -sf "$PYWAL_HYPR_CACHE" "$HYPR_COLORS_LINK"
    ln -sf "$PYWAL_QS_CACHE" "$QS_THEME_LINK"
    ln -sf "$PYWAL_WOFI_CACHE" "$WOFI_COLORS_LINK"

    reload_env
}

reload_env() {
    # Reload Hyprland
    hyprctl reload

    # Restart Quickshell
    # 'disown' is important to keep it running after script exits
    pkill quickshell
    quickshell &
    disown
}

# --- MENU LOGIC ---

# 1. Get list of static themes (folders in THEME_DIR)
# find outputs ./theme_name, so we cut to get just name
THEMES=$(find "$THEME_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)

# 2. Add "Pywal" as the first option
MENU_OPTIONS="pywal\n$THEMES"

# 3. Show Wofi menu
CHOICE=$(echo -e "$MENU_OPTIONS" | (cd "$HOME/.config/wofi" && wofi -dmenu -p "Select Theme"))

# 4. Handle selection
if [[ -z "$CHOICE" ]]; then
    exit 0
fi

case "$CHOICE" in
"pywal") apply_pywal ;;
*) apply_static "$CHOICE" ;;
esac

