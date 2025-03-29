#!/bin/bash

MAX_LENGTH=40      # Visible length of the text
SLEEP_INTERVAL=0.3 # Scrolling speed (lower = faster)
SCROLL_SPEED=2     # Characters shifted per step
TEMP_FILE="/tmp/polybar_spotify_index"

# Check if Spotify is running
if ! pgrep -x "spotify" > /dev/null; then
    echo ""
    [[ -f "$TEMP_FILE" ]] && rm "$TEMP_FILE"  # Clean up temp file if it exists
    exit 0
fi


get_song() {
    playerctl -p spotify metadata --format "{{ title }} - {{ artist }}" 2>/dev/null
}


get_icon() {
    case "$(playerctl -p spotify status 2>/dev/null)" in
        "Playing") echo "" ;;
        "Paused") echo "" ;;
        *) echo "" ;;
    esac
}


song=$(get_song)
icon=$(get_icon)


if [[ -z "$song" ]]; then
    echo ""
    [[ -f "$TEMP_FILE" ]] && rm "$TEMP_FILE"  # Remove temp file if no song is playing
    exit 0
fi


song="$song"
length=${#song}


if [[ ! -f "$TEMP_FILE" ]]; then
    echo "0" > "$TEMP_FILE"
fi
index=$(cat "$TEMP_FILE")


display_text="${song:index:MAX_LENGTH}"


if (( index + MAX_LENGTH >= length )); then
    index=0
else
    index=$((index + SCROLL_SPEED))
fi


echo "$index" > "$TEMP_FILE"
echo "$icon $display_text"
