#!/usr/bin/env bash
set -euo pipefail

log()  { printf '\033[1;32m[hypr-setup]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[hypr-setup]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[hypr-setup]\033[0m %s\n' "$*" >&2; exit 1; }

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    die "Run this as your normal user; sudo will be used only when needed."
fi

# Ensure basic directories exist
mkdir -p \
    "$HOME/.config/hypr" \
    "$HOME/.config/wofi" \
    "$HOME/.config/waybar" \
    "$HOME/.cache/wal" \
    "$HOME/Pictures/Screenshot"

install_arch() {
    local packages=(
        hyprland
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
        waybar
        wofi
        mako
        swww
        hyprlock
        hypridle
        copyq
        wl-clipboard
        grim
        slurp
        playerctl
        brightnessctl
        pavucontrol
        kitty
        foot
        thunar
        qt5-wayland
        qt6-wayland
        xorg-xwayland
        pipewire
        pipewire-pulse
        wireplumber
        networkmanager
        libnotify
    )

    log "Installing core Hyprland packages..."
    sudo pacman -S --needed --noconfirm "${packages[@]}"

    local aur_packages=(
        waypaper
        hyprshot
        wallutils
        rog-control-center
    )

    if command -v yay >/dev/null 2>&1; then
        log "Installing optional AUR packages with yay..."
        yay -S --needed --noconfirm "${aur_packages[@]}"
    elif command -v paru >/dev/null 2>&1; then
        log "Installing optional AUR packages with paru..."
        paru -S --needed --noconfirm "${aur_packages[@]}"
    else
        warn "No AUR helper (yay/paru) found."
        warn "Optional packages to install manually: ${aur_packages[*]}"
    fi
}

apply_dotfiles() {
    if command -v chezmoi >/dev/null 2>&1; then
        log "Applying chezmoi dotfiles..."
        chezmoi apply
    else
        warn "chezmoi not found; skipping dotfile apply"
    fi
}

prompt_reload() {
    echo
    read -r -p "Packages and dotfiles are updated. Reload Hyprland now? [y/N] " reply
    case "${reply,,}" in
        y|yes)
            if command -v hyprctl >/dev/null 2>&1; then
                log "Reloading Hyprland..."
                hyprctl reload || warn "hyprctl reload failed; log out and back in if needed."
            else
                warn "hyprctl not found. If you aren't in Hyprland yet, log out and select it in your display manager."
            fi
            ;;
        *)
            warn "Skipped reload. Please log out and back in when ready."
            ;;
    esac
}

main() {
    case "${1:-}" in
        -h|--help)
            cat <<'EOF'
Usage: setup.sh

Bootstrap Hyprland on Arch Linux:
  1) installs packages
  2) applies chezmoi dotfiles
  3) prompts to reload Hyprland
EOF
            exit 0
            ;;
    esac

    if command -v pacman >/dev/null 2>&1; then
        install_arch
    else
        die "This script is Arch-focused. Please install the equivalent packages for your distro manually."
    fi

    apply_dotfiles
    prompt_reload

    log "Done."
}

main "$@"
