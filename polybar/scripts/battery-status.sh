#!/bin/bash

battery_status=$(cat /sys/class/power_supply/BAT0/status)
battery_level=$(cat /sys/class/power_supply/BAT0/capacity)

case "$battery_status" in
    "Charging") icon="󰂄" ;;  # Charging icon
    "Discharging") icon="󰁾" ;;  # Discharging icon
    "Full") icon="󰂅" ;;  # Full icon
    *) icon="󰂑" ;;  # Unknown state
esac

echo "%{F#BF5A45}$icon%{F-} %{F#FFFFFF}$battery_level% %{F-}"

if [[ "$battery_level" -lt 20 && "$battery_status" == "Discharging" ]]; then
    dunstify -u critical "Low Battery" "Battery is at $battery_level%. Plug in the charger!"
fi
