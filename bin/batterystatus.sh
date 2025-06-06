#!/bin/bash

BATTERY=$(find /sys/class/power_supply/ -name "BAT*" | head -n1) || exit 0
THRESHOLD=20
COOLDOWN=60
TIMESTAMP_FILE=~/.cache/low_battery_last_notified

while true; do
    LEVEL=$(cat "$BATTERY/capacity")
    STATUS=$(cat "$BATTERY/status")

    if [ "$LEVEL" -le "$THRESHOLD" ] && [ "$STATUS" = "Discharging" ]; then
        NOW=$(date +%s)
        LAST_NOTIFIED=0

        if [ -f "$TIMESTAMP_FILE" ]; then
            LAST_NOTIFIED=$(cat "$TIMESTAMP_FILE")
        fi

        if (( NOW - LAST_NOTIFIED >= COOLDOWN )); then
            notify-send -u critical "Low Battery" "Battery is at ${LEVEL}%"
            echo "$NOW" > "$TIMESTAMP_FILE"
        fi
    else
        rm -f "$TIMESTAMP_FILE"
    fi

    sleep 60
done
