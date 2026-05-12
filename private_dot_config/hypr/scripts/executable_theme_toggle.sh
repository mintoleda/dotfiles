#!/usr/bin/env bash

# --- PATHS ---
THEME_DIR="$HOME/.config/hypr/themes"
THEME_COLORS_DIR="$THEME_DIR/colors"
HYPR_CONFIG_DIR="$HOME/.config/hypr/configs"
HYPR_COLORS_LINK="$HYPR_CONFIG_DIR/colors.conf"
HYPR_LUA_COLORS_LINK="$HYPR_CONFIG_DIR/colors.lua"
PYWAL_HYPR_CACHE="$HOME/.cache/wal/colors-hyprland.conf"
PYWAL_WOFI_CACHE="$HOME/.cache/wal/colors-waybar.css"
WOFI_COLORS_LINK="$HOME/.config/wofi/colors.css"
CURRENT_THEME_FILE="$HOME/.cache/current-theme"
STATIC_HYPR_COLORS="$HYPR_CONFIG_DIR/colors-static.conf"
STATIC_HYPR_LUA_COLORS="$HYPR_CONFIG_DIR/colors-static.lua"
OBSIDIAN_COLORS_SCRIPT="$HOME/.config/hypr/scripts/obsidian_colors.sh"

# --- FUNCTIONS ---

generate_obsidian_colors() {
    [[ -x "$OBSIDIAN_COLORS_SCRIPT" ]] && "$OBSIDIAN_COLORS_SCRIPT" || true
}

reset_theme_colors_dir() {
    mkdir -p "$THEME_COLORS_DIR"
    find "$THEME_COLORS_DIR" -maxdepth 1 -type f -delete
}

hex_from_hypr_value() {
    local value="$1"
    local hex=""

    if [[ "$value" =~ 0xff([[:xdigit:]]{6}) ]]; then
        hex="${BASH_REMATCH[1]}"
    elif [[ "$value" =~ rgba\(([[:xdigit:]]{6})[[:xdigit:]]{2}\) ]]; then
        hex="${BASH_REMATCH[1]}"
    elif [[ "$value" =~ rgb\(([[:xdigit:]]{6})\) ]]; then
        hex="${BASH_REMATCH[1]}"
    fi

    [[ -n "$hex" ]] && printf '#%s\n' "$hex"
}

css_color_value() {
    local name="$1"
    local css_file="$2"

    awk -v name="$name" '$1 == "@define-color" && $2 == name { gsub(/;/, "", $3); print $3; exit }' "$css_file"
}

hypr_color_value() {
    local name="$1"
    local hypr_file="$2"

    awk -F= -v name="\$${name}" '{
        key = $1
        sub(/^[[:space:]]+/, "", key)
        sub(/[[:space:]]+$/, "", key)
    }
    key == name {
        value = $2
        sub(/^[[:space:]]+/, "", value)
        sub(/[[:space:]]+$/, "", value)
        print value
        exit
    }' "$hypr_file"
}

theme_color() {
    local name="$1"
    local hypr_file="$2"
    local css_file="$3"
    local value=""

    if [[ -f "$css_file" ]]; then
        value=$(css_color_value "$name" "$css_file")
    fi

    if [[ -z "$value" && -f "$hypr_file" ]]; then
        value=$(hex_from_hypr_value "$(hypr_color_value "$name" "$hypr_file")")
    fi

    printf '%s\n' "$value"
}

lua_long_string() {
    printf '[[%s]]' "$1"
}

write_hyprland_lua_colors_from_conf() {
    local hypr_file="$1"
    local lua_file="$2"
    local wallpaper_value background_value foreground_value cursor_value active_value inactive_value i color_value

    wallpaper_value=$(hypr_color_value "wallpaper" "$hypr_file")
    background_value=$(hypr_color_value "backgroundCol" "$hypr_file")
    foreground_value=$(hypr_color_value "foregroundCol" "$hypr_file")
    cursor_value=$(hypr_color_value "cursor" "$hypr_file")
    active_value=$(hypr_color_value "activeBorder" "$hypr_file")
    inactive_value=$(hypr_color_value "inactiveBorder" "$hypr_file")

    {
        printf 'wallpaper = '; lua_long_string "$wallpaper_value"; printf '\n'
        printf 'backgroundCol = '; lua_long_string "$background_value"; printf '\n'
        printf 'foregroundCol = '; lua_long_string "$foreground_value"; printf '\n'
        printf 'cursor = '; lua_long_string "$cursor_value"; printf '\n\n'
        printf 'activeBorder = '; lua_long_string "$active_value"; printf '\n'
        printf 'inactiveBorder = '; lua_long_string "$inactive_value"; printf '\n\n'
        for i in {0..15}; do
            color_value=$(hypr_color_value "color$i" "$hypr_file")
            printf 'color%s = ' "$i"
            lua_long_string "$color_value"
            printf '\n'
        done
    } > "$lua_file"
}

write_current_theme_colors() {
    local theme_name="$1"
    local theme_path="$2"
    local hypr_file="$theme_path/hypr.conf"
    local css_file="$theme_path/colors.css"
    local wallpaper="$3"
    local colors=()
    local background foreground cursor color_name color_value i

    reset_theme_colors_dir

    background=$(theme_color "background" "$hypr_file" "$css_file")
    foreground=$(theme_color "foreground" "$hypr_file" "$css_file")
    cursor=$(theme_color "cursor" "$hypr_file" "$css_file")

    [[ -z "$background" ]] && background=$(hex_from_hypr_value "$(hypr_color_value "backgroundCol" "$hypr_file")")
    [[ -z "$foreground" ]] && foreground=$(hex_from_hypr_value "$(hypr_color_value "foregroundCol" "$hypr_file")")
    [[ -z "$cursor" ]] && cursor=$(hex_from_hypr_value "$(hypr_color_value "cursor" "$hypr_file")")

    for i in {0..15}; do
        color_name="color$i"
        color_value=$(theme_color "$color_name" "$hypr_file" "$css_file")
        [[ -z "$color_value" ]] && color_value="$foreground"
        colors[$i]="$color_value"
    done

    cat > "$THEME_COLORS_DIR/colors-hyprland.conf" <<EOF
\$wallpaper = $wallpaper
\$backgroundCol = 0xff${background#\#}
\$foregroundCol = 0xff${foreground#\#}
\$cursor = 0xff${cursor#\#}

\$activeBorder = $(hypr_color_value "activeBorder" "$hypr_file")
\$inactiveBorder = $(hypr_color_value "inactiveBorder" "$hypr_file")

# Standard colors
EOF

    for i in {0..15}; do
        printf '$color%s = 0xff%s\n' "$i" "${colors[$i]#\#}" >> "$THEME_COLORS_DIR/colors-hyprland.conf"
    done

    write_hyprland_lua_colors_from_conf "$THEME_COLORS_DIR/colors-hyprland.conf" "$THEME_COLORS_DIR/colors.lua"

    {
        printf '@define-color foreground %s;\n' "$foreground"
        printf '@define-color background %s;\n' "$background"
        printf '@define-color cursor %s;\n\n' "$cursor"
        for i in {0..15}; do
            printf '@define-color color%s %s;\n' "$i" "${colors[$i]}"
        done
    } > "$THEME_COLORS_DIR/colors-waybar.css"

    {
        printf 'wallpaper="%s"\n' "$wallpaper"
        printf 'background="%s"\n' "$background"
        printf 'foreground="%s"\n' "$foreground"
        printf 'cursor="%s"\n' "$cursor"
        for i in {0..15}; do
            printf 'color%s="%s"\n' "$i" "${colors[$i]}"
        done
    } > "$THEME_COLORS_DIR/colors.sh"

    {
        printf '{\n'
        printf '    "wallpaper": "%s",\n' "$wallpaper"
        printf '    "special": {\n'
        printf '        "background": "%s",\n' "$background"
        printf '        "foreground": "%s",\n' "$foreground"
        printf '        "cursor": "%s"\n' "$cursor"
        printf '    },\n'
        printf '    "colors": {\n'
        for i in {0..15}; do
            if [[ "$i" -lt 15 ]]; then
                printf '        "color%s": "%s",\n' "$i" "${colors[$i]}"
            else
                printf '        "color%s": "%s"\n' "$i" "${colors[$i]}"
            fi
        done
        printf '    }\n'
        printf '}\n'
    } > "$THEME_COLORS_DIR/colors.json"

    {
        printf 'wallpaper: "%s"\n\n' "$wallpaper"
        printf 'special:\n'
        printf '    background: "%s"\n' "$background"
        printf '    foreground: "%s"\n' "$foreground"
        printf '    cursor: "%s"\n\n' "$cursor"
        printf 'colors:\n'
        for i in {0..15}; do
            printf '    color%s: "%s"\n' "$i" "${colors[$i]}"
        done
    } > "$THEME_COLORS_DIR/colors.yml"

    {
        printf '$background: %s;\n' "$background"
        printf '$foreground: %s;\n' "$foreground"
        printf '$cursor: %s;\n' "$cursor"
        for i in {0..15}; do
            printf '$color%s: %s;\n' "$i" "${colors[$i]}"
        done
    } > "$THEME_COLORS_DIR/colors.scss"

    {
        printf 'import QtQuick\n\n'
        printf 'QtObject {\n'
        printf '    readonly property color background: "%s"\n' "$background"
        printf '    readonly property color foreground: "%s"\n' "$foreground"
        printf '    readonly property color cursor: "%s"\n\n' "$cursor"
        for i in {0..15}; do
            printf '    readonly property color color%s: "%s"\n' "$i" "${colors[$i]}"
        done
        printf '}\n'
    } > "$THEME_COLORS_DIR/colors.qml"

    {
        printf 'foreground %s\n' "$foreground"
        printf 'background %s\n' "$background"
        printf 'cursor %s\n\n' "$cursor"
        for i in {0..15}; do
            printf 'color%s %s\n' "$i" "${colors[$i]}"
        done
    } > "$THEME_COLORS_DIR/colors-kitty.conf"

    {
        printf '[colors.primary]\n'
        printf 'background = "%s"\n' "$background"
        printf 'foreground = "%s"\n\n' "$foreground"
        printf '[colors.cursor]\n'
        printf 'text = "%s"\n' "$background"
        printf 'cursor = "%s"\n\n' "$cursor"
        printf '[colors.normal]\n'
        printf 'black = "%s"\n' "${colors[0]}"
        printf 'red = "%s"\n' "${colors[1]}"
        printf 'green = "%s"\n' "${colors[2]}"
        printf 'yellow = "%s"\n' "${colors[3]}"
        printf 'blue = "%s"\n' "${colors[4]}"
        printf 'magenta = "%s"\n' "${colors[5]}"
        printf 'cyan = "%s"\n' "${colors[6]}"
        printf 'white = "%s"\n\n' "${colors[7]}"
        printf '[colors.bright]\n'
        printf 'black = "%s"\n' "${colors[8]}"
        printf 'red = "%s"\n' "${colors[9]}"
        printf 'green = "%s"\n' "${colors[10]}"
        printf 'yellow = "%s"\n' "${colors[11]}"
        printf 'blue = "%s"\n' "${colors[12]}"
        printf 'magenta = "%s"\n' "${colors[13]}"
        printf 'cyan = "%s"\n' "${colors[14]}"
        printf 'white = "%s"\n' "${colors[15]}"
    } > "$THEME_COLORS_DIR/colors-alacritty.toml"

    generate_obsidian_colors
}

sync_pywal_theme_colors() {
    reset_theme_colors_dir
    cp "$HOME"/.cache/wal/colors* "$THEME_COLORS_DIR"/ 2>/dev/null || true
    cp "$HOME"/.cache/wal/Colors.* "$THEME_COLORS_DIR"/ 2>/dev/null || true
    cp "$HOME"/.cache/wal/*.theme "$THEME_COLORS_DIR"/ 2>/dev/null || true
    cp "$HOME"/.cache/wal/*.conf "$THEME_COLORS_DIR"/ 2>/dev/null || true
    cp "$HOME"/.cache/wal/*.toml "$THEME_COLORS_DIR"/ 2>/dev/null || true
    cp "$HOME"/.cache/wal/*.yml "$THEME_COLORS_DIR"/ 2>/dev/null || true
    cp "$HOME"/.cache/wal/*.json "$THEME_COLORS_DIR"/ 2>/dev/null || true
    cp "$HOME"/.cache/wal/*.css "$THEME_COLORS_DIR"/ 2>/dev/null || true
    cp "$HOME"/.cache/wal/*.sh "$THEME_COLORS_DIR"/ 2>/dev/null || true
    cp "$HOME"/.cache/wal/*.qml "$THEME_COLORS_DIR"/ 2>/dev/null || true
    if [[ -f "$THEME_COLORS_DIR/colors-hyprland.conf" ]]; then
        write_hyprland_lua_colors_from_conf "$THEME_COLORS_DIR/colors-hyprland.conf" "$THEME_COLORS_DIR/colors.lua"
    fi
    generate_obsidian_colors
}

sync_static_theme_colors_to_wal() {
    mkdir -p "$HOME/.cache/wal"
    cp "$THEME_COLORS_DIR"/colors* "$HOME/.cache/wal"/ 2>/dev/null || true
}

link_pywal_colors() {
    mkdir -p "$HOME/.cache/wal"

    if [[ -f "$PYWAL_HYPR_CACHE" ]]; then
        sync_pywal_theme_colors
        ln -sf "$THEME_COLORS_DIR/colors-hyprland.conf" "$HYPR_COLORS_LINK"
        ln -sf "$THEME_COLORS_DIR/colors.lua" "$HYPR_LUA_COLORS_LINK"
    else
        notify-send "Theme" "Pywal Hypr colors missing, falling back to static colors"
        ln -sf "$STATIC_HYPR_COLORS" "$HYPR_COLORS_LINK"
        ln -sf "$STATIC_HYPR_LUA_COLORS" "$HYPR_LUA_COLORS_LINK"
    fi

    if [[ -f "$PYWAL_WOFI_CACHE" ]]; then
        ln -sf "$THEME_COLORS_DIR/colors-waybar.css" "$WOFI_COLORS_LINK"
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
        write_current_theme_colors "$theme_name" "$theme_path" ""
        sync_static_theme_colors_to_wal
        # Link generated current-theme color files directly
        [[ -f "$THEME_COLORS_DIR/colors-hyprland.conf" ]] && ln -sf "$THEME_COLORS_DIR/colors-hyprland.conf" "$HYPR_COLORS_LINK"
        [[ -f "$THEME_COLORS_DIR/colors.lua" ]] && ln -sf "$THEME_COLORS_DIR/colors.lua" "$HYPR_LUA_COLORS_LINK"
        [[ -f "$THEME_COLORS_DIR/colors-waybar.css" ]] && ln -sf "$THEME_COLORS_DIR/colors-waybar.css" "$WOFI_COLORS_LINK"
        # Waybar imports directly from the pywal cache path, so update it too
        [[ -f "$THEME_COLORS_DIR/colors-waybar.css" ]] && cp "$THEME_COLORS_DIR/colors-waybar.css" "$PYWAL_WOFI_CACHE"
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
THEMES=$(find "$THEME_DIR" -mindepth 1 -maxdepth 1 -type d ! -name colors -printf "%f\n" | sort)

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
