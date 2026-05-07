#!/bin/bash
WALLPAPER_DIR="$HOME/wallpapers/walls"
THEME_COLORS_DIR="$HOME/.config/hypr/themes/colors"
OBSIDIAN_COLORS_SCRIPT="$HOME/.config/hypr/scripts/obsidian_colors.sh"
#I dont know what the fuck I am doing
generate_obsidian_colors() {
    [[ -x "$OBSIDIAN_COLORS_SCRIPT" ]] && "$OBSIDIAN_COLORS_SCRIPT" || true
}

sync_pywal_theme_colors() {
    mkdir -p "$THEME_COLORS_DIR"
    find "$THEME_COLORS_DIR" -maxdepth 1 -type f -delete
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
    generate_obsidian_colors
}

menu() {
    find "${WALLPAPER_DIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | awk '{print "img:"$0}'
}
main() {
    choice=$(menu | (cd "$HOME/.config/wofi" && wofi -c ~/.config/wofi/wallpaper -s ~/.config/wofi/style-wallpaper.css --show dmenu --prompt "Select Wallpaper:"))
    selected_wallpaper=$(echo "$choice" | sed 's/^img://')
    swww img "$selected_wallpaper" --transition-type any --transition-fps 60 --transition-duration .5
    wal -i "$selected_wallpaper" -n --cols16
    sync_pywal_theme_colors
    makoctl reload
    pywalfox update
    color1=$(awk 'match($0, /color2=\47(.*)\47/,a) { print a[1] }' ~/.config/hypr/themes/colors/colors.sh)
    color2=$(awk 'match($0, /color3=\47(.*)\47/,a) { print a[1] }' ~/.config/hypr/themes/colors/colors.sh)
    cava_config="$HOME/.config/cava/config"
    sed -i "s/^gradient_color_1 = .*/gradient_color_1 = '$color1'/" $cava_config
    sed -i "s/^gradient_color_2 = .*/gradient_color_2 = '$color2'/" $cava_config
    pkill -USR2 cava 2>/dev/null
    source ~/.config/hypr/themes/colors/colors.sh && cp -r $wallpaper ~/wallpapers/pywallpaper.jpg
}
main
