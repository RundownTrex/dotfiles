#!/bin/bash

# Dynamic icon timer script for polybar
# Different icons for idle, running, and paused states

TIMER_DIR="/tmp/polybar-timer"

# Get current time in seconds since epoch
now() { 
    date --utc +%s
}

# Check if timer is active
timer_active() {
    [ -e "$TIMER_DIR" ]
}

# Check if timer is paused
timer_paused() {
    [ -f "$TIMER_DIR/paused" ]
}

# Get expiry time
get_expiry() {
    cat "$TIMER_DIR/expiry" 2>/dev/null || echo 0
}

# Get action to perform on completion
get_action() {
    cat "$TIMER_DIR/action" 2>/dev/null || echo ""
}

# Get seconds left when paused
get_paused_seconds() {
    cat "$TIMER_DIR/paused" 2>/dev/null || echo 0
}

# Calculate minutes left when paused (rounding up)
get_paused_minutes() {
    echo $(( ( $(get_paused_seconds) + 59 ) / 60 ))
}

# Calculate seconds left
get_seconds_left() {
    echo $(( $(get_expiry) - $(now) ))
}

# Calculate minutes left (rounding up)
get_minutes_left() {
    echo $(( ( $(get_seconds_left) + 59 ) / 60 ))
}

# Show a notification with the expiry time
print_expiry_time() {
    notify-send -u low -r 12345 "Timer expires at $( date -d "$(get_seconds_left) sec" +"%I:%M %p")"
}

# Show a notification that the timer is paused
print_paused() {
    notify-send -u low -r 12345 "Timer paused"
}

# Remove any notifications
remove_notifications() {
    notify-send -C 12345
}

update_display() {
    # Check if timer has expired
    if timer_active; then
        if { timer_paused && [ $(get_paused_minutes) -le 0 ]; } || \
           { ! timer_paused && [ $(get_minutes_left) -le 0 ]; }; then
            # Timer has expired
            eval "$(get_action)" 2>/dev/null 1>/dev/null
            rm -rf "$TIMER_DIR"
            remove_notifications
        fi
    fi

    # Output with different icons for different states
    if timer_active; then
        if timer_paused; then
            # Paused timer - use pause icon
            echo "%{F#BF5A45}%{F-} $(get_paused_minutes)"
        else
            # Active timer - use play icon
            echo "%{F#BF5A45}%{F-} $(get_minutes_left)"
        fi
    else
        # Idle - use timer icon
        echo "%{F#BF5A45}"
    fi
}

case "$1" in
    tail)
        # Set up signal handler for updating display
        trap update_display USR1
        
        # Main loop
        while true; do
            update_display
            sleep ${2:-1} &
            wait
        done
        ;;
        
    update)
        # Send signal to update display
        kill -USR1 "$(pgrep --oldest --parent ${2})" 2>/dev/null
        ;;
        
    new)
        # Create new timer
        mkdir -p "$TIMER_DIR"
        echo "$(( $(now) + 60*${2} ))" > "$TIMER_DIR/expiry"
        echo "${3}" > "$TIMER_DIR/action"
        print_expiry_time
        ;;
        
    increase)
        if timer_active; then
            if timer_paused; then
                echo "$(( $(get_paused_seconds) + ${2} ))" > "$TIMER_DIR/paused"
            else
                echo "$(( $(get_expiry) + ${2} ))" > "$TIMER_DIR/expiry"
                print_expiry_time
            fi
        else
            exit 1
        fi
        ;;
        
    cancel)
        rm -rf "$TIMER_DIR"
        remove_notifications
        ;;
        
    togglepause)
        if timer_active; then
            if timer_paused; then
                # Resume timer
                echo "$(( $(now) + $(get_paused_seconds) ))" > "$TIMER_DIR/expiry"
                rm -f "$TIMER_DIR/paused"
                print_expiry_time
            else
                # Pause timer
                get_seconds_left > "$TIMER_DIR/paused"
                rm -f "$TIMER_DIR/expiry"
                print_paused
            fi
        else
            exit 1
        fi
        ;;
        
    *)
        echo "Usage: $0 {tail|update|new|increase|cancel|togglepause}"
        exit 1
        ;;
esac
