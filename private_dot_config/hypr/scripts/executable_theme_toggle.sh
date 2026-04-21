#!/usr/bin/env bash

# --- PATHS ---
THEME_DIR="$HOME/.config/hypr/themes"
HYPR_CONFIG_DIR="$HOME/.config/hypr/configs"
HYPR_COLORS_LINK="$HYPR_CONFIG_DIR/colors.conf"
PYWAL_HYPR_CACHE="$HOME/.cache/wal/colors-hyprland.conf"
PYWAL_WOFI_CACHE="$HOME/.cache/wal/colors-waybar.css"
WOFI_COLORS_LINK="$HOME/.config/wofi/colors.css"
CURRENT_THEME_FILE="$HOME/.cache/current-theme"
STATIC_HYPR_COLORS="$HYPR_CONFIG_DIR/colors-static.conf"

# --- FUNCTIONS ---

link_pywal_colors() {
    mkdir -p "$HOME/.cache/wal"

    if [[ -f "$PYWAL_HYPR_CACHE" ]]; then
        ln -sf "$PYWAL_HYPR_CACHE" "$HYPR_COLORS_LINK"
    else
        notify-send "Theme" "Pywal Hypr colors missing, falling back to static colors"
        ln -sf "$STATIC_HYPR_COLORS" "$HYPR_COLORS_LINK"
    fi

    if [[ -f "$PYWAL_WOFI_CACHE" ]]; then
        ln -sf "$PYWAL_WOFI_CACHE" "$WOFI_COLORS_LINK"
    fi
}

apply_pywal() {
    echo "pywal" > "$CURRENT_THEME_FILE"
    notify-send "Theme" "Switching to Pywal..."

    # Link Pywal generated files, or fall back if they don't exist yet.
    link_pywal_colors

    reload_env
}

apply_static() {
    local theme_name="$1"
    local theme_path="$THEME_DIR/$theme_name"

    echo "$theme_name" > "$CURRENT_THEME_FILE"
    notify-send "Theme" "Switching to $theme_name..."

    # Set Wallpaper
    local wallpaper=$(find "$theme_path" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" \) -print -quit)
    if [[ -n "$wallpaper" ]]; then
        waypaper --wallpaper "$wallpaper"
        wal -i "$wallpaper" -n --cols16
        # Link Pywal generated files, or fall back if generation failed.
        link_pywal_colors
    else
        notify-send "Theme" "No wallpaper found in $theme_name, applying colors only"
        # Link static theme color files directly
        [[ -f "$theme_path/hypr.conf" ]] && ln -sf "$theme_path/hypr.conf" "$HYPR_COLORS_LINK"
        [[ -f "$theme_path/colors.css" ]] && ln -sf "$theme_path/colors.css" "$WOFI_COLORS_LINK"
        # Waybar imports directly from the pywal cache path, so update it too
        [[ -f "$theme_path/colors.css" ]] && cp "$theme_path/colors.css" "$PYWAL_WOFI_CACHE"
    fi

    reload_env
}

reload_env() {
    # Reload Hyprland
    hyprctl reload

    # Restart Waybar
    # 'disown' is important to keep it running after script exits
    pkill waybar
    waybar &
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
