#!/bin/bash

# toggle-eco.sh
# Usage: ./toggle-eco.sh [on|off]
# on:  Switches to Quiet profile, disables animations/shadows
# off: Switches to Balanced profile, enables animations/shadows

MODE=$1

if [ -z "$MODE" ]; then
    echo "Usage: $0 [on|off]"
    exit 1
fi

if [ "$MODE" == "on" ]; then
    # Enable Eco Mode
    asusctl profile set Quiet
    hyprctl keyword animations:enabled 0
    hyprctl keyword decoration:shadow:enabled 0
elif [ "$MODE" == "off" ]; then
    # Disable Eco Mode (Restore Standard)
    asusctl profile set Balanced
    hyprctl keyword animations:enabled 1
    hyprctl keyword decoration:shadow:enabled 1
fi
