#!/usr/bin/env python3
"""
Last.fm scrobbler daemon for ytm.fish.

Monitors mpv playback via IPC socket and scrobbles tracks to Last.fm.
Reads track metadata from .info.json files created by yt-dlp.

Usage (called automatically by ytm.fish):
    python3 ytm_scrobbler.py <mpv_socket_path> <cache_dir>
"""

import hashlib
import json
import os
import socket
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path


CONFIG_FILE = os.path.expanduser("~/.config/ytmusic/lastfm.json")
API_ROOT = "https://ws.audioscrobbler.com/2.0/"

# Scrobble thresholds (Last.fm rules)
MIN_SCROBBLE_TIME = 30        # Minimum 30 seconds played
SCROBBLE_PERCENT = 0.5        # 50% of track
SCROBBLE_MAX_TIME = 4 * 60    # Or 4 minutes, whichever comes first


def load_config() -> dict | None:
    """Load Last.fm credentials from config file."""
    if not os.path.exists(CONFIG_FILE):
        return None
    try:
        with open(CONFIG_FILE) as f:
            config = json.load(f)
        if all(k in config for k in ("api_key", "api_secret", "session_key")):
            return config
    except (json.JSONDecodeError, IOError):
        pass
    return None


def api_sig(params: dict, secret: str) -> str:
    """Generate Last.fm API signature."""
    sorted_params = "".join(f"{k}{v}" for k, v in sorted(params.items()))
    return hashlib.md5((sorted_params + secret).encode("utf-8")).hexdigest()


def api_call(params: dict, config: dict) -> dict | None:
    """Make a signed API call to Last.fm."""
    params["api_key"] = config["api_key"]
    params["sk"] = config["session_key"]
    params["api_sig"] = api_sig(params, config["api_secret"])
    params["format"] = "json"
    
    try:
        data = urllib.parse.urlencode(params).encode("utf-8")
        req = urllib.request.Request(API_ROOT, data=data, method="POST")
        req.add_header("User-Agent", "ytm-scrobbler/1.0")
        
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception:
        return None


def update_now_playing(artist: str, track: str, config: dict, 
                       album: str = None, duration: int = None) -> bool:
    """Update 'Now Playing' status on Last.fm."""
    params = {
        "method": "track.updateNowPlaying",
        "artist": artist,
        "track": track,
    }
    if album:
        params["album"] = album
    if duration:
        params["duration"] = str(int(duration))
    
    result = api_call(params, config)
    return result is not None and "error" not in result


def scrobble(artist: str, track: str, timestamp: int, config: dict,
             album: str = None, duration: int = None) -> bool:
    """Submit a scrobble to Last.fm."""
    params = {
        "method": "track.scrobble",
        "artist": artist,
        "track": track,
        "timestamp": str(timestamp),
    }
    if album:
        params["album"] = album
    if duration:
        params["duration"] = str(int(duration))
    
    result = api_call(params, config)
    return result is not None and "error" not in result


def get_mpv_property(sock_path: str, prop: str):
    """Query a property from mpv via IPC socket."""
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.settimeout(2)
        s.connect(sock_path)
        s.sendall(json.dumps({"command": ["get_property", prop]}).encode() + b"\n")
        data = s.recv(8192)
        s.close()
        
        for line in data.decode("utf-8", errors="replace").strip().split("\n"):
            try:
                r = json.loads(line)
                if "data" in r:
                    return r["data"]
            except json.JSONDecodeError:
                continue
    except Exception:
        pass
    return None


def extract_first_artist(artist_str: str) -> str:
    """Extract the first artist from a multi-artist string."""
    if not artist_str:
        return artist_str
    
    # Common separators: ", " / " & " / " and " / " x " / " feat. " / " ft. "
    import re
    # Split on common multi-artist separators
    parts = re.split(r'\s*[,&]\s*|\s+and\s+|\s+x\s+|\s+feat\.?\s+|\s+ft\.?\s+', artist_str, flags=re.IGNORECASE)
    
    if parts:
        return parts[0].strip()
    return artist_str


def extract_metadata_from_json(json_path: str) -> dict | None:
    """Extract artist, track, album from yt-dlp info.json file."""
    try:
        with open(json_path, encoding="utf-8") as f:
            info = json.load(f)
        
        # Try different fields for artist (in order of preference)
        artist_raw = (
            info.get("artist") or
            info.get("creator") or
            info.get("uploader") or
            info.get("channel") or
            "Unknown Artist"
        )
        
        # Extract only the first artist from multi-artist strings
        artist = extract_first_artist(artist_raw)
        
        # Try different fields for track name
        track = (
            info.get("track") or
            info.get("title") or
            "Unknown Track"
        )
        
        # Album (optional)
        album = info.get("album")
        
        # Duration
        duration = info.get("duration")
        
        return {
            "artist": artist,
            "track": track,
            "album": album,
            "duration": duration,
        }
    except Exception:
        return None


def find_info_json(mp3_path: str) -> str | None:
    """Find the .info.json file corresponding to an mp3 file."""
    # yt-dlp creates .info.json with the same base name
    # e.g., "Song [ID].mp3" -> "Song [ID].info.json"
    base = mp3_path.rsplit(".", 1)[0]  # Remove .mp3
    json_path = base + ".info.json"
    
    if os.path.exists(json_path):
        return json_path
    return None


def parse_filename_fallback(filepath: str) -> dict:
    """Fallback: parse artist/track from filename if no .info.json."""
    filename = os.path.basename(filepath)
    
    # Remove extension
    name = filename.rsplit(".", 1)[0]
    
    # Remove [ID] suffix
    import re
    name = re.sub(r'\s*\[[^\]]+\]\s*$', '', name)
    
    # Try to split "Artist - Track"
    if " - " in name:
        parts = name.split(" - ", 1)
        return {
            "artist": parts[0].strip(),
            "track": parts[1].strip(),
            "album": None,
            "duration": None,
        }
    
    # Fallback: use whole name as track, unknown artist
    return {
        "artist": "Unknown Artist",
        "track": name.strip(),
        "album": None,
        "duration": None,
    }


def get_track_metadata(filepath: str) -> dict:
    """Get metadata for a track, preferring .info.json over filename parsing."""
    json_path = find_info_json(filepath)
    
    if json_path:
        metadata = extract_metadata_from_json(json_path)
        if metadata:
            return metadata
    
    # Fallback to filename parsing
    return parse_filename_fallback(filepath)


class ScrobblerState:
    """Tracks the current playback state for scrobbling decisions."""
    
    def __init__(self):
        self.current_path = None
        self.current_metadata = None
        self.track_start_time = None
        self.played_time = 0.0
        self.last_position = 0.0
        self.scrobbled = False
        self.now_playing_sent = False
    
    def reset(self, path: str = None, metadata: dict = None):
        """Reset state for a new track."""
        self.current_path = path
        self.current_metadata = metadata
        self.track_start_time = int(time.time()) if path else None
        self.played_time = 0.0
        self.last_position = 0.0
        self.scrobbled = False
        self.now_playing_sent = False


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <mpv_socket> <cache_dir>", file=sys.stderr)
        sys.exit(1)
    
    sock_path = sys.argv[1]
    cache_dir = sys.argv[2]
    
    # Load Last.fm config
    config = load_config()
    if not config:
        # No config = scrobbling disabled, exit silently
        sys.exit(0)
    
    # Wait for mpv socket to appear
    for _ in range(60):
        if os.path.exists(sock_path):
            break
        time.sleep(0.25)
    else:
        sys.exit(1)
    
    state = ScrobblerState()
    poll_interval = 2.0
    
    while os.path.exists(sock_path):
        try:
            # Get current track path
            path = get_mpv_property(sock_path, "path")
            
            if path is None:
                # mpv might be between tracks or shutting down
                time.sleep(poll_interval)
                continue
            
            # Check if track changed
            if path != state.current_path:
                # New track started
                metadata = get_track_metadata(path)
                state.reset(path, metadata)
                
                # Send "Now Playing" update
                if metadata and metadata.get("artist") and metadata.get("track"):
                    success = update_now_playing(
                        metadata["artist"],
                        metadata["track"],
                        config,
                        album=metadata.get("album"),
                        duration=metadata.get("duration"),
                    )
                    state.now_playing_sent = success
            
            # Track playback progress
            position = get_mpv_property(sock_path, "playback-time")
            paused = get_mpv_property(sock_path, "pause")
            duration = get_mpv_property(sock_path, "duration")
            
            if position is not None and not paused:
                # Accumulate played time (handles seeks correctly)
                if position > state.last_position:
                    state.played_time += position - state.last_position
                state.last_position = position
            
            # Check if we should scrobble
            if (not state.scrobbled and 
                state.current_metadata and 
                state.track_start_time and
                duration is not None):
                
                # Calculate scrobble threshold
                scrobble_threshold = min(
                    duration * SCROBBLE_PERCENT,
                    SCROBBLE_MAX_TIME
                )
                
                # Scrobble if played enough and minimum time met
                if (state.played_time >= scrobble_threshold and 
                    state.played_time >= MIN_SCROBBLE_TIME):
                    
                    metadata = state.current_metadata
                    if metadata.get("artist") and metadata.get("track"):
                        success = scrobble(
                            metadata["artist"],
                            metadata["track"],
                            state.track_start_time,
                            config,
                            album=metadata.get("album"),
                            duration=duration,
                        )
                        state.scrobbled = success
            
            time.sleep(poll_interval)
            
        except Exception:
            time.sleep(poll_interval)
    
    # mpv socket gone, exit cleanly
    sys.exit(0)


if __name__ == "__main__":
    main()
