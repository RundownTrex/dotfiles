function ytmusic

    set name $argv[1]

    switch $name	
		case main
            set url "https://www.youtube.com/playlist?list=PLxH47DqCr2rQ_BTMae91GKIoZ16-_rTzW"

        case aniso
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
            else
                echo "Usage: ytmusic [main|anison|genshin|dragonspine|peak|bocchi|beatles|riajuu|katarenai|oregairu|kon|vocaloid|pino|deco|miku|<url>]"
                return
            end
    end

    # Set up cache directory
    set -l cache_dir "$HOME/.cache/ytmusic/$name"
    mkdir -p $cache_dir

    echo "How would you like to play?"
    echo "  1) Shuffle play"
    echo "  2) Play in order"
    echo "  3) Cancel"
    read -P "Choose [1/2/3]: " choice

    switch $choice
        case 1
            set -l shuffle true
        case 2
            set -l shuffle false
        case '*'
            echo "Cancelled."
            return
    end

    # Fetch playlist track IDs (fast, metadata only)
    echo "Fetching playlist info..."
    set -l ids (yt-dlp --flat-playlist --print id "$url")

    if test (count $ids) -eq 0
        echo "No tracks found."
        return
    end

    echo (count $ids)" tracks found."

    # Shuffle the ID list if requested
    if test "$shuffle" = true
        set ids (printf '%s\n' $ids | shuf)
    end

    set -l total (count $ids)

    for i in (seq $total)
        set -l id $ids[$i]

        # Wait for any background prefetch to finish
        wait 2>/dev/null

        # Check if track is already cached
        set -l track_file (find $cache_dir -name "*\[$id\].mp3" 2>/dev/null | head -1)

        # Download if not cached
        if test -z "$track_file"
            echo "[$i/$total] Downloading..."
            yt-dlp -x --audio-format mp3 --audio-quality 0 \
                -o "$cache_dir/%(title)s [%(id)s].%(ext)s" \
                -- "$id"
            set track_file (find $cache_dir -name "*\[$id\].mp3" 2>/dev/null | head -1)
        end

        if test -z "$track_file"
            echo "[$i/$total] Failed to get track, skipping."
            continue
        end

        # Prefetch next track in background while this one plays
        if test $i -lt $total
            set -l next_id $ids[(math $i + 1)]
            if test -z (find $cache_dir -name "*\[$next_id\].mp3" 2>/dev/null | head -1)
                bash -c '
                    yt-dlp -x --audio-format mp3 --audio-quality 0 \
                        -o "$1/%(title)s [%(id)s].%(ext)s" \
                        -- "$2" >/dev/null 2>&1
                ' _ "$cache_dir" "$next_id" &
            end
        end

        # Play from cache
        echo "[$i/$total] Playing"
        mpv --no-video --term-playing-msg='Now Playing: ${media-title}' "$track_file"
    end
end
