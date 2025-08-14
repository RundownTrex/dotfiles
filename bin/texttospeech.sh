#!/bin/bash
# ~/.local/bin/text-to-speech
TEXT=$(rofi -dmenu -p "Enter text to speak:")
if [ -n "$TEXT" ]; then
    VOICE=$(echo -e "Default\nFemale\nMale\nRobot" | rofi -dmenu -p "Choose voice:")
    case "$VOICE" in
        "Female") espeak -v f5 "$TEXT" ;;
        "Male") espeak -v m1 "$TEXT" ;;
        "Robot") espeak -v whisper "$TEXT" ;;
        *) espeak "$TEXT" ;;
    esac
    notify-send -i audio-speakers "Text-to-Speech" "Speaking: $(echo "$TEXT" | cut -c1-30)..."
fi
