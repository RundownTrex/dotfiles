#!/bin/bash
# changeBrightness

msgTag="mybrightness"

# Change brightness using brightnessctl
if [[ "$1" == *"+"* ]]; then
    brightnessctl set "$1"
elif [[ "$1" == *"-"* ]]; then
    brightnessctl set "$1"
else
    # Handle direct percentage values like "50%"
    brightnessctl set "$1"
fi

# Get current brightness as percentage
brightness=$(brightnessctl get)
max_brightness=$(brightnessctl max)
percentage=$((brightness * 100 / max_brightness))

# Update polybar hook
polybar-msg hook nightlight 1

# Send notification with dunstify
if [[ $percentage -le 10 ]]; then
    icon="display-brightness-low"
elif [[ $percentage -le 30 ]]; then
    icon="display-brightness-medium"
else
    icon="display-brightness-high"
fi

dunstify -a "changeBrightness" -u low -i "$icon" -h string:x-dunst-stack-tag:"$msgTag" -h int:value:"$percentage" "Brightness: ${percentage}%"
