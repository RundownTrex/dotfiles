#!/usr/bin/env bash

#polybar-msg cmd quit
killall -q polybar

# Kill any existing bluetooth monitor
pkill -f "bt-battery-monitor.sh monitor"

echo "---" | tee -a /tmp/polybar1.log
polybar main 2>&1 | tee -a /tmp/polybar1.log & disown

# Start bluetooth monitor in background
~/.config/polybar/scripts/bt-battery-monitor.sh monitor &

echo "Bars launched..."
