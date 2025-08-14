#!/bin/bash

# Configuration
BRIGHTNESS_STEP="5%"

get_brightness() {
    # Get current brightness percentage from brightnessctl using machine-readable format
    # Format: device,class,current,percent,max
    # Example: intel_backlight,backlight,141,15%,937
    brightnessctl -m | cut -d',' -f4
}

get_status() {
    local brightness=$(get_brightness)
    
    if pgrep -x "redshift" > /dev/null; then
        echo "󰌶 %{F#FFFFFF}${brightness}%{F-}"
    else
        echo "󰌵 %{F#FFFFFF}${brightness}%{F-}"
    fi
}

case "$1" in
    "on")
        pkill redshift 2>/dev/null
        redshift -O 4000 &
        ;;
    "off")
        redshift -x
        pkill redshift 2>/dev/null
        ;;
    "brightness_up")
        brightnessctl set +$BRIGHTNESS_STEP
        get_status
        ;;
    "brightness_down")
        brightnessctl set $BRIGHTNESS_STEP-
        get_status
        ;;
    *)
        get_status
        ;;
esac
