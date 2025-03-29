#!/bin/bash

get_status() {
    if dunstctl is-paused | grep -q "true"; then
        echo " 󰂛 "
    else
        echo " 󰂚 "
    fi
}

if [[ "$1" == "toggle" ]]; then
    dunstctl set-paused toggle
fi

get_status
