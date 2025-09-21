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

    battery_level=$(bluetoothctl info "$DEVICE_MAC" | grep "Battery Percentage" | sed 's/.*(\([0-9]*\)).*/\1/')

    if [[ -z "$battery_level" ]]; then
        echo ""
    else
        printf "| %s%%" "$battery_level"
    fi
}

# Function to monitor bluetooth events and trigger polybar updates
monitor_bluetooth() {
    dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path_namespace='/org/bluez'" 2>/dev/null | \
    while read -r line; do
        if echo "$line" | grep -q "Connected\|Battery"; then
            # Small delay to ensure the change is processed
            sleep 0.5
            # Trigger polybar update
            polybar-msg hook bluetooth-battery 1 2>/dev/null
        fi
    done
}

# If called with "monitor" argument, start monitoring
if [[ "$1" == "monitor" ]]; then
    monitor_bluetooth
else
    # Default behavior - just get and display battery
    get_battery
fi
