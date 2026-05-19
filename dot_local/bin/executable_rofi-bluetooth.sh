#!/usr/bin/env bash
#             __ _       _     _            _              _   _
#  _ __ ___  / _(_)     | |__ | |_   _  ___| |_ ___   ___ | |_| |__
# | '__/ _ \| |_| |_____| '_ \| | | | |/ _ \ __/ _ \ / _ \| __| '_ \
# | | | (_) |  _| |_____| |_) | | |_| |  __/ || (_) | (_) | |_| | | |
# |_|  \___/|_| |_|     |_.__/|_|\__,_|\___|\__\___/ \___/ \__|_| |_|
#
# Author: Nick Clyde (clydedroid)
# Modified: Uses D-Bus for queries (bluetoothctl v5.86+ non-interactive mode is broken)
#
# A script that generates a rofi menu that uses bluetoothctl to
# connect to bluetooth devices and display status info.
#
# Depends on:
#   Arch repositories: rofi, bluez-utils (contains bluetoothctl)

# Constants
divider="---------"
goback="Back"

# ──────────────────────────────────────────────
# D-Bus helpers (work without a TTY, unlike bluetoothctl v5.86+)
# ──────────────────────────────────────────────

# Get a property from the adapter via D-Bus
_adapter_prop() {
    dbus-send --system --print-reply --dest=org.bluez \
        /org/bluez/hci0 \
        org.freedesktop.DBus.Properties.Get \
        string:"org.bluez.Adapter1" string:"$1" 2>/dev/null | \
        grep -oP '(boolean|string) \K.*' | tr -d '"'
}

# Get a property from a device via D-Bus
_device_prop() {
    local mac_path
    mac_path=$(echo "$1" | tr ':' '_')
    dbus-send --system --print-reply --dest=org.bluez \
        "/org/bluez/hci0/dev_${mac_path}" \
        org.freedesktop.DBus.Properties.Get \
        string:"org.bluez.Device1" string:"$2" 2>/dev/null | \
        grep -oP '(boolean|string|byte) \K.*' | tr -d '"'
}

# Set a property on the adapter via D-Bus
_adapter_set() {
    dbus-send --system --print-reply --dest=org.bluez \
        /org/bluez/hci0 \
        org.freedesktop.DBus.Properties.Set \
        string:"org.bluez.Adapter1" string:"$1" \
        "variant:boolean:$2" 2>/dev/null > /dev/null
}

# List all device MAC addresses (only top-level devices, not sub-objects)
_list_device_macs() {
    dbus-send --system --print-reply --dest=org.bluez / \
        org.freedesktop.DBus.ObjectManager.GetManagedObjects 2>/dev/null | \
        grep -oP 'object path "/org/bluez/hci0/dev_\K[A-F0-9_]+(?=")' | \
        sort -u | tr '_' ':'
}

# Connect/disconnect a device via D-Bus
_device_connect() {
    local mac_path
    mac_path=$(echo "$1" | tr ':' '_')
    dbus-send --system --print-reply --dest=org.bluez \
        "/org/bluez/hci0/dev_${mac_path}" \
        org.bluez.Device1.Connect 2>/dev/null > /dev/null
}

_device_disconnect() {
    local mac_path
    mac_path=$(echo "$1" | tr ':' '_')
    dbus-send --system --print-reply --dest=org.bluez \
        "/org/bluez/hci0/dev_${mac_path}" \
        org.bluez.Device1.Disconnect 2>/dev/null > /dev/null
}

_device_pair() {
    local mac_path
    mac_path=$(echo "$1" | tr ':' '_')
    dbus-send --system --print-reply --dest=org.bluez \
        "/org/bluez/hci0/dev_${mac_path}" \
        org.bluez.Device1.Pair 2>/dev/null > /dev/null
}

_device_remove() {
    local mac_path
    mac_path=$(echo "$1" | tr ':' '_')
    dbus-send --system --print-reply --dest=org.bluez \
        /org/bluez/hci0 \
        org.bluez.Adapter1.RemoveDevice \
        "objpath:/org/bluez/hci0/dev_${mac_path}" 2>/dev/null > /dev/null
}

_device_trust() {
    local mac_path
    mac_path=$(echo "$1" | tr ':' '_')
    dbus-send --system --print-reply --dest=org.bluez \
        "/org/bluez/hci0/dev_${mac_path}" \
        org.freedesktop.DBus.Properties.Set \
        string:"org.bluez.Device1" string:"Trusted" \
        "variant:boolean:$1" 2>/dev/null > /dev/null
}

_device_set_trusted() {
    local mac_path
    mac_path=$(echo "$1" | tr ':' '_')
    dbus-send --system --print-reply --dest=org.bluez \
        "/org/bluez/hci0/dev_${mac_path}" \
        org.freedesktop.DBus.Properties.Set \
        string:"org.bluez.Device1" string:"Trusted" \
        "variant:boolean:$2" 2>/dev/null > /dev/null
}

# Start/stop scanning via D-Bus
_adapter_start_discovery() {
    dbus-send --system --print-reply --dest=org.bluez \
        /org/bluez/hci0 \
        org.bluez.Adapter1.StartDiscovery 2>/dev/null > /dev/null
}

_adapter_stop_discovery() {
    dbus-send --system --print-reply --dest=org.bluez \
        /org/bluez/hci0 \
        org.bluez.Adapter1.StopDiscovery 2>/dev/null > /dev/null
}

# ──────────────────────────────────────────────
# High-level functions
# ──────────────────────────────────────────────

# Checks if bluetooth controller is powered on
power_on() {
    [[ "$(_adapter_prop Powered)" == "true" ]]
}

# Toggles power state
toggle_power() {
    if power_on; then
        _adapter_set Powered false
        show_menu
    else
        if rfkill list bluetooth | grep -q 'blocked: yes'; then
            rfkill unblock bluetooth && sleep 3
        fi
        _adapter_set Powered true
        show_menu
    fi
}

# Checks if controller is scanning for new devices
scan_on() {
    if [[ "$(_adapter_prop Discovering)" == "true" ]]; then
        echo "Scan: on"
        return 0
    else
        echo "Scan: off"
        return 1
    fi
}

# Toggles scanning state
toggle_scan() {
    if scan_on; then
        _adapter_stop_discovery
        show_menu
    else
        _adapter_start_discovery &
        echo "Scanning..."
        sleep 5
        show_menu
    fi
}

# Checks if controller is able to pair to devices
pairable_on() {
    if [[ "$(_adapter_prop Pairable)" == "true" ]]; then
        echo "Pairable: on"
        return 0
    else
        echo "Pairable: off"
        return 1
    fi
}

# Toggles pairable state
toggle_pairable() {
    if pairable_on; then
        _adapter_set Pairable false
        show_menu
    else
        _adapter_set Pairable true
        show_menu
    fi
}

# Checks if controller is discoverable by other devices
discoverable_on() {
    if [[ "$(_adapter_prop Discoverable)" == "true" ]]; then
        echo "Discoverable: on"
        return 0
    else
        echo "Discoverable: off"
        return 1
    fi
}

# Toggles discoverable state
toggle_discoverable() {
    if discoverable_on; then
        _adapter_set Discoverable false
        show_menu
    else
        _adapter_set Discoverable true
        show_menu
    fi
}

# Checks if a device is connected
device_connected() {
    [[ "$(_device_prop "$1" Connected)" == "true" ]]
}

# Toggles device connection
toggle_connection() {
    if device_connected "$1"; then
        _device_disconnect "$1"
        sleep 1
        device_menu "$device"
    else
        _device_connect "$1"
        sleep 2
        device_menu "$device"
    fi
}

# Checks if a device is paired
device_paired() {
    if [[ "$(_device_prop "$1" Paired)" == "true" ]]; then
        echo "Paired: yes"
        return 0
    else
        echo "Paired: no"
        return 1
    fi
}

# Toggles device paired state
toggle_paired() {
    if device_paired "$1"; then
        _device_remove "$1"
        sleep 1
        device_menu "$device"
    else
        _device_pair "$1"
        sleep 2
        device_menu "$device"
    fi
}

# Checks if a device is trusted
device_trusted() {
    if [[ "$(_device_prop "$1" Trusted)" == "true" ]]; then
        echo "Trusted: yes"
        return 0
    else
        echo "Trusted: no"
        return 1
    fi
}

# Toggles device trust
toggle_trust() {
    if device_trusted "$1"; then
        _device_set_trusted "$1" false
        device_menu "$device"
    else
        _device_set_trusted "$1" true
        device_menu "$device"
    fi
}

# Prints a short string with the current bluetooth status
# Useful for status bars like polybar, etc.
print_status() {
    if power_on; then
        printf ''

        local counter=0
        for mac in $(_list_device_macs); do
            if device_connected "$mac"; then
                local device_alias
                device_alias=$(_device_prop "$mac" Alias)
                if [ $counter -gt 0 ]; then
                    printf ", %s" "$device_alias"
                else
                    printf " %s" "$device_alias"
                fi
                ((counter++))
            fi
        done
        printf "\n"
    else
        echo ""
    fi
}

# A submenu for a specific device that allows connecting, pairing, and trusting
device_menu() {
    device=$1

    # Get device name and mac address
    device_name=$(echo "$device" | cut -d ' ' -f 3-)
    mac=$(echo "$device" | cut -d ' ' -f 2)

    # Build options
    if device_connected "$mac"; then
        connected="Connected: yes"
    else
        connected="Connected: no"
    fi
    paired=$(device_paired "$mac")
    trusted=$(device_trusted "$mac")
    options="$connected\n$paired\n$trusted\n$divider\n$goback\nExit"

    # Open rofi menu, read chosen option
    chosen="$(echo -e "$options" | $rofi_command "$device_name")"

    # Match chosen option to command
    case "$chosen" in
        "" | "$divider")
            echo "No option chosen."
            ;;
        "$connected")
            toggle_connection "$mac"
            ;;
        "$paired")
            toggle_paired "$mac"
            ;;
        "$trusted")
            toggle_trust "$mac"
            ;;
        "$goback")
            show_menu
            ;;
    esac
}

# Opens a rofi menu with current bluetooth status and options to connect
show_menu() {
    # Get menu options
    if power_on; then
        power="Power: on"

        # Human-readable names of devices, one per line
        local devices=""
        for mac in $(_list_device_macs); do
            local name
            name=$(_device_prop "$mac" Alias)
            if [ -n "$name" ]; then
                if [ -n "$devices" ]; then
                    devices="$devices\n$name"
                else
                    devices="$name"
                fi
            fi
        done

        # Get controller flags
        scan=$(scan_on)
        pairable=$(pairable_on)
        discoverable=$(discoverable_on)

        # Options passed to rofi
        options="$devices\n$divider\n$power\n$scan\n$pairable\n$discoverable\nExit"
    else
        power="Power: off"
        options="$power\nExit"
    fi

    # Open rofi menu, read chosen option
    chosen="$(echo -e "$options" | $rofi_command "Bluetooth")"

    # Match chosen option to command
    case "$chosen" in
        "" | "$divider")
            echo "No option chosen."
            ;;
        "$power")
            toggle_power
            ;;
        "$scan")
            toggle_scan
            ;;
        "$discoverable")
            toggle_discoverable
            ;;
        "$pairable")
            toggle_pairable
            ;;
        *)
            # Find the device MAC matching the chosen name
            local chosen_mac=""
            for mac in $(_list_device_macs); do
                local name
                name=$(_device_prop "$mac" Alias)
                if [[ "$name" == "$chosen" ]]; then
                    chosen_mac="$mac"
                    break
                fi
            done
            if [[ -n "$chosen_mac" ]]; then
                device_menu "Device $chosen_mac $chosen"
            fi
            ;;
    esac
}

# Rofi command to pipe into, can add any options here
rofi_command="rofi -dmenu $* -p"

case "$1" in
    --status)
        print_status
        ;;
    *)
        show_menu
        ;;
esac
