#!/bin/bash

# idle.sh — manage hypridle via direct process control
# Usage: idle.sh [start|stop|toggle]

case "$1" in
    start)
        if ! pgrep -x hypridle >/dev/null; then
            hypridle &
            disown
        fi
        ;;
    stop)
        if pgrep -x hypridle >/dev/null; then
            notify-send "Auto-Lock" "Auto-lock off"
            sleep 0.3
            pkill -x hypridle
        fi
        ;;
    toggle)
        if pgrep -x hypridle >/dev/null; then
            # Send notification BEFORE stopping, so mako is still healthy
            notify-send "Auto-Lock" "Auto-lock off"
            sleep 0.3
            pkill -x hypridle
        else
            hypridle &
            disown
            notify-send "Auto-Lock" "Auto-lock on"
        fi
        ;;
    *)
        echo "Usage: $0 [start|stop|toggle]"
        exit 1
        ;;
esac
