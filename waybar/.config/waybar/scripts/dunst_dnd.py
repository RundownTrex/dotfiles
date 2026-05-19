#!/usr/bin/env python3

import subprocess as sp
import json
import sys

def toggle_mute():
    """Toggle Dunst notifications."""
    sp.run(["dunstctl", "set-paused", "toggle"], check=True)

def is_muted():
    """Return True if Dunst is paused (DND on)."""
    result = sp.check_output(["dunstctl", "is-paused"]).strip()
    return result == b"true"

def print_status():
    """Output JSON for Waybar."""
    if is_muted():
        icon = " "  # Muted bell (Font Awesome)
        color = "#FF5555"
        tooltip = "Do Not Disturb: ON"
    else:
        icon = ""  # Regular bell
        color = "#50FA7B"
        tooltip = "Do Not Disturb: OFF"

    print(json.dumps({
        "text": icon,
        "tooltip": tooltip,
        "class": "dunst-dnd",
        "alt": "dnd-on" if is_muted() else "dnd-off",
        "color": color
    }))

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--toggle":
        toggle_mute()
    print_status()
