#!/bin/bash

# Polybar Date Module with Popup Calendar (i3-compatible)
# - Displays time (default) or full date (toggled via --toggle-format)
# - Right-click opens a yad calendar popup (--toggle-calendar)

FORMAT_FILE="/tmp/polybar-date-format"
LOCK_FILE="/tmp/polybar-calendar.lock"

toggle_format() {
    if [ -f "$FORMAT_FILE" ]; then
        rm -f "$FORMAT_FILE"
    else
        touch "$FORMAT_FILE"
    fi
}

toggle_calendar() {
    if [ -f "$LOCK_FILE" ]; then
        pid=$(cat "$LOCK_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            rm -f "$LOCK_FILE"
            return
        fi
        rm -f "$LOCK_FILE"
    fi

    yad --calendar \
        --fixed \
        --no-buttons \
        --title="Calendar" \
        --geometry=250x200+558+28 \
        --skip-taskbar \
        > /dev/null 2>&1 &
    echo $! > "$LOCK_FILE"
}

case "$1" in
    --toggle-format)
        toggle_format
        ;;
    --toggle-calendar)
        toggle_calendar
        ;;
    *)
        if [ -f "$FORMAT_FILE" ]; then
            date +'%I:%M:%S %p, %a, %d-%m-%y'
        else
            date +'%I:%M %p'
        fi
        ;;
esac
