#!/bin/bash

# Helper: run bluetoothctl commands in interactive mode (non-interactive is broken in v5.86)
btctl() {
    echo -e "$1\nquit\n" | bluetoothctl 2>/dev/null
}

get_bluetooth_device() {
    MAC=$(btctl "devices Connected" | grep "^Device" | awk '{print $2}' | head -n 1)
    echo "$MAC"
}

get_battery() {
    local DEVICE_MAC
    DEVICE_MAC=$(get_bluetooth_device)

    if [[ -z "$DEVICE_MAC" ]]; then
        echo "" 
        exit 0
    fi

    local battery_level=""

    # Method 1: Try bluetoothctl info - parse "Battery Percentage: 0xNN (NN)"
    battery_level=$(btctl "info $DEVICE_MAC" | grep -i "Battery Percentage" | grep -oP '\(\K[0-9]+(?=\))')

    # Method 2: If bluetoothctl didn't return battery, try upower (what Blueman uses)
    if [[ -z "$battery_level" ]]; then
        local mac_underscored
        mac_underscored=$(echo "$DEVICE_MAC" | tr ':' '_')
        local upower_path
        upower_path=$(upower -e 2>/dev/null | grep -i "$mac_underscored")
        if [[ -n "$upower_path" ]]; then
            battery_level=$(upower -i "$upower_path" 2>/dev/null | grep "percentage" | grep -oP '[0-9]+')
        fi
    fi

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
