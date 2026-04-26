#!/bin/bash

# Script to handle volume and brightness changes with notifications

function get_volume {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}' | cut -d. -f1
}

function is_mute {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED"
}

function get_brightness {
    brightnessctl -m 2>/dev/null \
        | awk -F, 'NR==1 { gsub(/%/, "", $4); print $4 }'
}

function send_notification {
    local type=$1
    if [ "$type" == "volume" ]; then
        local vol=$(get_volume)
        if is_mute; then
            notify-send -e -u low -c volume -h string:x-canonical-private-synchronous:volume -h int:value:0 -i audio-volume-muted-symbolic "Muted"
        else
            local icon="audio-volume-high-symbolic"
            if [ "$vol" -lt 33 ]; then icon="audio-volume-low-symbolic"; 
            elif [ "$vol" -lt 66 ]; then icon="audio-volume-medium-symbolic"; fi
            notify-send -e -u low -c volume -h string:x-canonical-private-synchronous:volume -h int:value:"$vol" -i "$icon" "Volume: ${vol}%"
        fi
    elif [ "$type" == "brightness" ]; then
        local br=$(get_brightness)
        [ -n "$br" ] || br=0
        notify-send -e -u low -c brightness -h string:x-canonical-private-synchronous:brightness -h int:value:"$br" -i display-brightness-symbolic "Backlight: ${br}%"
    fi
}

case $1 in
    vol_up)
        wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
        send_notification volume
        ;;
    vol_down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        send_notification volume
        ;;
    vol_mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        send_notification volume
        ;;
    br_up)
        brightnessctl -e4 -n2 set 5%+ >/dev/null 2>&1
        send_notification brightness
        ;;
    br_down)
        brightnessctl -e4 -n2 set 5%- >/dev/null 2>&1
        send_notification brightness
        ;;
esac
