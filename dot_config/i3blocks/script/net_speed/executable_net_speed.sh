#!/bin/bash

# Network interface (modify if needed)
INTERFACE=$(ip route | awk '/default/ {print $5; exit}')

# Get previous values (if any)
RX_PREV=$(cat /tmp/rx_prev 2>/dev/null || echo 0)
TX_PREV=$(cat /tmp/tx_prev 2>/dev/null || echo 0)

# Read current values from /proc/net/dev
RX_CUR=$(cat /proc/net/dev | grep "$INTERFACE" | awk '{print $2}')
TX_CUR=$(cat /proc/net/dev | grep "$INTERFACE" | awk '{print $10}')

# Calculate speed in KB/s
RX_SPEED=$(( (RX_CUR - RX_PREV) / 1024 ))
TX_SPEED=$(( (TX_CUR - TX_PREV) / 1024 ))

# Store current values for next run
echo $RX_CUR > /tmp/rx_prev
echo $TX_CUR > /tmp/tx_prev

# Output for i3blocks
echo "${RX_SPEED} KB/s ${TX_SPEED} KB/s"
