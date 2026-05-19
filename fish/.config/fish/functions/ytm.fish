function ytm

    set name $argv[1]

    switch $name
		case main
            set url "https://www.youtube.com/playlist?list=PLxH47DqCr2rQ_BTMae91GKIoZ16-_rTzW"

        case anison
            set url "https://music.youtube.com/playlist?list=PLxH47DqCr2rTt4Xjq3jhXOMN-FXwFfIJQ"

        case genshin
            set url "https://music.youtube.com/playlist?list=PLxH47DqCr2rRWCzKMV1RkPnBHdJa7KH-o"

		case dragonspine
	    	set url "https://music.youtube.com/playlist?list=PLxH47DqCr2rTt1xT4HyzcCyZmBZhGqApx"

		case peak
			set url "https://music.youtube.com/playlist?list=PLxH47DqCr2rSqJiLZT8YuA--GmLbtHEtJ"

		case bocchi
			set url "https://music.youtube.com/playlist?list=PLxH47DqCr2rQtbEDcl4pycft7IvLkd4_f"

		case beatles
			set url "https://music.youtube.com/playlist?list=PLxH47DqCr2rRwK8e7UD7LVzZAYGUyjGsq"

		case riajuu
			set url "https://music.youtube.com/playlist?list=PLxH47DqCr2rR94z6z6wPnmJ9Hsfq-wLw0"

		case katarenai
			set url "https://music.youtube.com/playlist?list=PLxH47DqCr2rQZJp1xG9IT0gOQcpsWx_6a"

		case oregairu
			set url "https://music.youtube.com/playlist?list=PLxH47DqCr2rSPCajYurbj5su8D1r22o8v"

		case kon
			set url "https://music.youtube.com/playlist?list=PLxH47DqCr2rTs3yEt3UzdpKu2egd70pYD"

		case vocaloid
			set url "https://music.youtube.com/playlist?list=PLxH47DqCr2rQG_GUFH1lxSk3iyXc5fjcq"

		case pino
			set url "https://music.youtube.com/playlist?list=PLxH47DqCr2rTiZW1QVMtWfBHekbHpU0g8"

		case deco
			set url "https://music.youtube.com/playlist?list=PLxH47DqCr2rRNRAoJ8NIeUIFNkIxU3NBt"

		case miku
			set url "https://music.youtube.com/playlist?list=PLxH47DqCr2rRqF5k364l0q3o6oVTB9eFc"

        case '*'
            if string match -rq '^https?://(www\.)?(youtube\.com|music\.youtube\.com|youtu\.be)/' -- $name
                set url $name
                # Use a hash for cache dir name when a raw URL is passed
                set name (printf '%s' $name | md5sum | string split -f1 ' ')
            else
                echo "Usage: ytm [main|anison|genshin|dragonspine|peak|bocchi|beatles|riajuu|katarenai|oregairu|kon|vocaloid|pino|deco|miku|<url>]"
                return
            end
    end

    # --- Setup ---
    set -l cache_dir "$HOME/.cache/ytmusic/songs"
    set -l sock /tmp/ytm_mpv_(random).sock
    mkdir -p $cache_dir

    echo "How would you like to play?"
    echo "  1) Shuffle play"
    echo "  2) Play in order"
    echo "  3) Cancel"
    read -P "Choose [1/2/3]: " choice

    set -l shuffle false
    switch $choice
        case 1
            set shuffle true
        case 2
            set shuffle false
        case '*'
            echo "Cancelled."
            return
    end

    # --- Fetch playlist metadata ---
    echo "Fetching playlist info..."
    # Fetch both ID and title using a unique separator unlikely to appear in titles
    set -l separator "|||"
    set -l playlist_data (yt-dlp --flat-playlist --print "%(id)s|||%(title)s" "$url")

    if test (count $playlist_data) -eq 0
        echo "No tracks found."
        return
    end

    # Parse into separate arrays
    set -l ids
    set -l titles
    for line in $playlist_data
        set -l parts (string split "$separator" -- $line)
        set -a ids $parts[1]
        set -a titles $parts[2]
    end

    set -l total (count $ids)
    echo "$total tracks found."
    echo

    # --- Display playlist and let user choose starting song ---
    echo "Playlist:"
    for i in (seq 1 $total)
        printf "%3d. %s\n" $i "$titles[$i]"
    end
    echo

    # Prompt for starting song
    if test "$shuffle" = true
        set -l default_start (random 1 $total)
        read -P "Start from [1-$total, Enter=random($default_start)]: " start_choice
        if test -z "$start_choice"
            set start_choice $default_start
        end
    else
        read -P "Start from [1-$total, Enter=1]: " start_choice
        if test -z "$start_choice"
            set start_choice 1
        end
    end

    # Validate input
    if not string match -rq '^\d+$' -- "$start_choice"
        echo "Invalid input. Cancelled."
        return
    end
    set start_choice (math $start_choice) # ensure it's a number
    if test $start_choice -lt 1 -o $start_choice -gt $total
        echo "Invalid track number. Must be between 1 and $total."
        return
    end

    # --- Reorder playlist to start from selected song ---
    # For shuffle: shuffle first, then rotate to start from selection
    # For in-order: rotate to start from selection, rest follows in order
    if test "$shuffle" = true
        # Shuffle the playlist
        set -l shuffle_indices (seq 1 $total | shuf)
        set -l shuffled_ids
        set -l shuffled_titles
        for i in $shuffle_indices
            set -a shuffled_ids $ids[$i]
            set -a shuffled_titles $titles[$i]
        end
        set ids $shuffled_ids
        set titles $shuffled_titles
        
        # Find where our chosen song ended up after shuffle and rotate to it
        # But actually, user chose from ORIGINAL list, so we need to find that ID
        set -l chosen_id $ids[1] # placeholder
        # Re-parse to get the original chosen ID before shuffle
        set -l orig_parts (string split "$separator" -- $playlist_data[$start_choice])
        set chosen_id $orig_parts[1]
        
        # Find this ID in shuffled list and rotate
        set -l found_idx 1
        for i in (seq 1 $total)
            if test "$ids[$i]" = "$chosen_id"
                set found_idx $i
                break
            end
        end
        
        if test $found_idx -gt 1
            set ids $ids[$found_idx..-1] $ids[1..(math $found_idx - 1)]
            set titles $titles[$found_idx..-1] $titles[1..(math $found_idx - 1)]
        end
    else
        # In-order: rotate playlist to start from chosen song
        if test $start_choice -gt 1
            set ids $ids[$start_choice..-1] $ids[1..(math $start_choice - 1)]
            set titles $titles[$start_choice..-1] $titles[1..(math $start_choice - 1)]
        end
    end

    echo
    echo "Starting from: $titles[1]"

    # --- Ensure first track is cached ---
    set -l first_id $ids[1]
    set -l first_file (find $cache_dir -name "*\[$first_id\].mp3" 2>/dev/null | head -1)

    if test -z "$first_file"
        echo "Downloading first track..."
        yt-dlp -x --audio-format mp3 --audio-quality 0 \
            --write-info-json \
            -o "$cache_dir/%(title)s [%(id)s].%(ext)s" \
            -- "$first_id"
        set first_file (find $cache_dir -name "*\[$first_id\].mp3" 2>/dev/null | head -1)
    end

    if test -z "$first_file"
        echo "Failed to download first track."
        return
    end

    # --- Write remaining IDs to a temp file for the prefetcher ---
    set -l id_file (mktemp /tmp/ytm_ids.XXXXXX)
    if test (count $ids) -gt 1
        printf '%s\n' $ids[2..-1] > $id_file
    else
        printf '' > $id_file
    end

    # --- Background prefetcher ---
    # Uses a SINGLE persistent ncat connection to mpv's IPC socket.
    # Cached tracks are added instantly. Uncached tracks only download
    # when mpv is within 2 tracks of needing them (saves bandwidth).
    set -l helper_script (status dirname)/ytm_helper.py
    set -l scrobbler_script (status dirname)/ytm_scrobbler.py
    bash -c '
        sock="$1"; cache="$2"; idfile="$3"; helper="$4"

        # Wait for mpv IPC socket to appear
        for i in $(seq 1 60); do
            [ -S "$sock" ] && break
            sleep 0.25
        done

        [ -S "$sock" ] || { rm -f "$idfile"; exit 1; }

        loaded=0  # tracks added to mpv after the first one

        # All commands go through one persistent ncat connection (no broken pipes)
        {
            while IFS= read -r id; do
                [ -S "$sock" ] || break

                # Check cache
                cached=$(find "$cache" -name "*\[${id}\].mp3" 2>/dev/null | head -1)

                if [ -z "$cached" ]; then
                    # UNCACHED: wait until mpv actually needs this track
                    while [ -S "$sock" ]; do
                        pos=$(python3 "$helper" "$sock" "playlist-pos" 2>/dev/null)
                        [ "$pos" = "-1" ] && break 2
                        # ahead = how many unplayed tracks are queued
                        ahead=$(( loaded + 1 - pos - 1 ))
                        [ "$ahead" -le 2 ] && break
                        sleep 2
                    done

                    [ -S "$sock" ] || break

                    yt-dlp -x --audio-format mp3 --audio-quality 0 \
                        --write-info-json \
                        -o "${cache}/%(title)s [%(id)s].%(ext)s" \
                        -- "$id" >/dev/null 2>&1
                    cached=$(find "$cache" -name "*\[${id}\].mp3" 2>/dev/null | head -1)
                fi

                # Append to mpv playlist (append-play = auto-resume if mpv is idle)
                if [ -n "$cached" ] && [ -S "$sock" ]; then
                    json_path=$(printf "%s" "$cached" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")
                    printf "{\"command\": [\"loadfile\", %s, \"append-play\"]}\n" "$json_path"
                    loaded=$((loaded + 1))
                fi
            done < "$idfile"
            rm -f "$idfile"

            # Keep connection alive until mpv exits
            while [ -S "$sock" ]; do sleep 1; done
        } | ncat -U "$sock" >/dev/null 2>&1
    ' _ "$sock" "$cache_dir" "$id_file" "$helper_script" &
    disown

    # --- Background scrobbler (if configured) ---
    # Monitors mpv and scrobbles to Last.fm when tracks are played
    if test -f "$HOME/.config/ytmusic/lastfm.json"
        python3 "$scrobbler_script" "$sock" "$cache_dir" &
        disown
    end

    # --- Play (foreground) ---
    # mpv runs with IPC server; prefetcher adds tracks in the background.
    # Full controls: > (next), < (prev), L (loop), space (pause), q (quit)
    echo "Starting playback... (tracks will be added as they cache)"
    echo "Controls: > next | < prev | L loop | space pause | q quit"
    mpv --no-video \
        --volume=60 \
        --input-ipc-server="$sock" \
        --idle=yes \
        --loop-playlist=inf \
        --term-playing-msg='Now Playing: ${media-title}' \
        "$first_file"

    # --- Cleanup ---
    rm -f $sock
end
