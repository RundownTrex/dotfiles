#!/bin/bash
# filepath: ~/.config/waybar/scripts/spotify.sh

MAX_LENGTH=40
SCROLL_SPEED=2
SCROLL_FILE="/tmp/waybar_spotify_scroll"

# Check if Spotify is running
if ! pgrep -x "spotify" > /dev/null; then
    echo '{"text": "", "class": "inactive"}'
    [[ -f "$SCROLL_FILE" ]] && rm "$SCROLL_FILE"
    exit 0
fi

# Get song info
song=$(playerctl -p spotify metadata --format "{{ title }} - {{ artist }}. " 2>/dev/null)
status=$(playerctl -p spotify status 2>/dev/null)
icon=""
[[ "$status" == "Playing" ]] && icon=""
[[ "$status" == "Paused" ]] && icon=""

if [[ -z "$song" ]]; then
    echo '{"text": "", "class": "inactive"}'
    [[ -f "$SCROLL_FILE" ]] && rm "$SCROLL_FILE"
    exit 0
fi

# Count characters using awk (UTF-8 safe)
char_count=$(echo -n "$song" | awk '{print length}')

# Load scroll index
[[ -f "$SCROLL_FILE" ]] || echo 0 > "$SCROLL_FILE"
index=$(cat "$SCROLL_FILE")

# Scroll if needed
if (( char_count > MAX_LENGTH )); then
    # Slice UTF-8 string using awk
    display_text=$(echo "$song" | awk -v i="$index" -v len="$MAX_LENGTH" '
    {
        n = split($0, a, "")
        for (j = i+1; j <= i+len; j++) {
            printf "%s", a[(j-1) % n + 1]
        }
    }')

    # Update index
    index=$(( (index + SCROLL_SPEED) % char_count ))
    echo "$index" > "$SCROLL_FILE"
else
    display_text="$song"
    rm -f "$SCROLL_FILE"
fi

# Escape for GTK/JSON
escape_markup() {
    sed -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' \
        -e 's/"/\&quot;/g' \
        -e "s/'/\&apos;/g"
}

display_text_escaped=$(echo "$display_text" | escape_markup)
song_escaped=$(echo "$song" | escape_markup)

# Output
echo "{\"text\": \"$icon $display_text_escaped\", \"tooltip\": \"$song_escaped\", \"class\": \"playing\"}"
