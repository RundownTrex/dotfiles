#!/bin/bash

MAX_LENGTH=35      # Visible length of the text
SLEEP_INTERVAL=0.3 # Scrolling speed (lower = faster)
SCROLL_SPEED=2     # Characters shifted per step
TEMP_FILE="/tmp/polybar_music_index"
PLAYER_FILE="/tmp/polybar_music_active_player"

# List of known music players (spotify/spotify_player for Spotify, browser players for YT Music, mpv)
SPOTIFY_PLAYERS="spotify spotify_player"
BROWSER_PLAYERS="chromium chrome firefox brave edge opera vivaldi"
MPV_PLAYERS="mpv"

# Find active music player, preferring the most recently active one
get_active_player() {
    local best_player=""
    local best_status=""

    # Get all available players
    local all_players
    all_players=$(playerctl -l 2>/dev/null) || return 1

    # First pass: look for a "Playing" player
    while IFS= read -r player; do
        local status
        status=$(playerctl -p "$player" status 2>/dev/null)
        local base_player="${player%%.*}"  # e.g., "edge.instance1734" -> "edge"

        # Check if this is a known music player
        local is_music_player=false
        for sp in $SPOTIFY_PLAYERS; do
            [[ "$base_player" == "$sp" ]] && is_music_player=true && break
        done
        for bp in $BROWSER_PLAYERS; do
            [[ "$base_player" == "$bp" ]] && is_music_player=true && break
        done
        for mp in $MPV_PLAYERS; do
            [[ "$base_player" == "$mp" ]] && is_music_player=true && break
        done

        $is_music_player || continue

        if [[ "$status" == "Playing" ]]; then
            echo "$player"
            return 0
        elif [[ "$status" == "Paused" && -z "$best_player" ]]; then
            best_player="$player"
            best_status="Paused"
        fi
    done <<< "$all_players"

    # Return paused player if no playing player found
    if [[ -n "$best_player" ]]; then
        echo "$best_player"
        return 0
    fi

    return 1
}

# Get the icon based on the player type
get_player_icon() {
    local player="$1"
    local base_player="${player%%.*}"

    for sp in $SPOTIFY_PLAYERS; do
        [[ "$base_player" == "$sp" ]] && echo "" && return
    done

    for mp in $MPV_PLAYERS; do
        [[ "$base_player" == "$mp" ]] && echo "" && return
    done

    # YT Music (browser-based) icon
    echo ""
}

# Get the active player
active_player=$(get_active_player)

if [[ -z "$active_player" ]]; then
    echo ""
    [[ -f "$TEMP_FILE" ]] && rm "$TEMP_FILE"
    [[ -f "$PLAYER_FILE" ]] && rm "$PLAYER_FILE"
    exit 0
fi

# Save the active player name for click actions
echo "$active_player" > "$PLAYER_FILE"

get_song() {
    local base_player="${active_player%%.*}"
    for mp in $MPV_PLAYERS; do
        if [[ "$base_player" == "$mp" ]]; then
            playerctl -p "$active_player" metadata --format "{{ title }}" 2>/dev/null
            return
        fi
    done
    playerctl -p "$active_player" metadata --format "{{ title }} - {{ artist }}" 2>/dev/null
}

get_status_icon() {
    case "$(playerctl -p "$active_player" status 2>/dev/null)" in
        "Playing") echo "" ;;
        "Paused") echo "" ;;
        *) echo "" ;;
    esac
}

song=$(get_song)
status_icon=$(get_status_icon)
player_icon=$(get_player_icon "$active_player")

if [[ -z "$song" ]]; then
    echo ""
    [[ -f "$TEMP_FILE" ]] && rm "$TEMP_FILE"
    [[ -f "$PLAYER_FILE" ]] && rm "$PLAYER_FILE"
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
echo "$player_icon $status_icon $display_text"
