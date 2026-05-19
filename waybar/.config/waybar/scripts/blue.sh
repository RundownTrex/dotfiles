#!/bin/bash

# Check if Bluetooth is on
status=$(bluetoothctl show | grep "Powered: yes")
devices=$(bluetoothctl devices Connected | awk '{print $2}')

if [[ -z "$status" ]]; then
    echo "⨯"
elif [[ -z "$devices" ]]; then
    echo "🔵 -"
else
    output="🔵"
    for dev in $devices; do
        name=$(bluetoothctl info "$dev" | grep "Name" | awk -F ": " '{print $2}')
        battery=$(bluetoothctl info "$dev" | grep "Battery Percentage" | awk -F ": " '{print $2}' | tr -d '%')
	#battery=$(bluetoothctl info "$dev" | grep "Battery Percentage" | awk '{print $3}' | sed 's/([^)]*)//g' | tr -d '()x')

        # Check if the battery value is in hexadecimal format (starts with 0x)
        #if [[ "$battery" == 0x* ]]; then
        #    battery=$(printf "%d" "$battery") # Convert hex to decimal
        #fi

        if [[ -n "$battery" ]]; then
            output+="${battery}% "
        else
            output+=" $name (No Battery Info) "
        fi
    done
    echo "$output"
fi
