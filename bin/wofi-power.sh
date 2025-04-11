#!/bin/bash

# Define the power menu options
OPTIONS=" Shutdown\n Restart\n Suspend\n Logout"

# Show the options in wofi and store the selected option
CHOSEN=$(echo -e "$OPTIONS" | wofi --dmenu --width=250 --height=200 --lines=4 --cache-file /dev/null)

# Perform the selected action
case "$CHOSEN" in
    " Shutdown") systemctl poweroff ;;
    " Restart") systemctl reboot ;;
    " Suspend") systemctl suspend ;;
    " Logout") hyprctl dispatch exit ;;
    *) exit 1 ;;  # Exit if no valid option is chosen
esac
