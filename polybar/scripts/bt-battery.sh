#!/bin/bash

get_bluetooth_device() {
    MAC=$(bluetoothctl devices Connected | awk '{print $2}' | head -n 1)
    echo "$MAC"
}

get_battery() {
    local DEVICE_MAC
    DEVICE_MAC=$(get_bluetooth_device)

    if [[ -z "$DEVICE_MAC" ]]; then
        echo "" 
        exit 0
    fi

    battery_level=$(bluetoothctl info "$DEVICE_MAC" | grep "Battery Percentage" | awk '{print $3}' | tr -d '%')

    if [[ -z "$battery_level" ]]; then
        echo ""
    else
        printf "| %.0f%%\n  " "$battery_level"
    fi
}

get_battery
