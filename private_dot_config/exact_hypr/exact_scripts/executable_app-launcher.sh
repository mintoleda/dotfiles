#!/usr/bin/env bash
cd "$HOME/.config/wofi" || exit

# Toggle: if wofi is running, close it and exit
pkill wofi && exit 0

# Collect app names from .desktop files, show in dmenu (layer surface)
choice=$(
    grep -rh '^Name=' /usr/share/applications/*.desktop ~/.local/share/applications/*.desktop 2>/dev/null |
    cut -d= -f2- | sort -u |
    wofi -dmenu -i -p "Search"
)

[ -z "$choice" ] && exit 0

# Find and launch the selected app
desktop=$(grep -rl "^Name=$choice$" /usr/share/applications/ ~/.local/share/applications/ 2>/dev/null | head -1)
[ -n "$desktop" ] && gtk-launch "$(basename "$desktop" .desktop)" &
