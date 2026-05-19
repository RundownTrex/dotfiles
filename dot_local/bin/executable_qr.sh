#!/bin/bash

export ADW_DISABLE_PORTAL=1

TEXT=$(zenity --text-info --editable --title="Enter text for QR code" --width=500 --height=400 2>/dev/null)

if [ -n "$TEXT" ]; then
    QR_FILE="/tmp/qr_$(date +%s).png"
    qrencode -o "$QR_FILE" "$TEXT"
    if [ -f "$QR_FILE" ]; then
        feh "$QR_FILE" &
        notify-send -i camera-photo "QR Code" "Generated and displayed QR code"
        sleep 10
        rm -f "$QR_FILE"
    else
        notify-send -i dialog-error "QR Code" "Failed to generate QR code"
    fi
else
    notify-send -i dialog-information "QR Code" "No text entered, operation cancelled"
fi
