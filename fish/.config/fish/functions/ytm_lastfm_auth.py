#!/usr/bin/env python3
"""
One-time Last.fm authentication setup for ytm.fish scrobbler.

Usage:
    python3 ytm_lastfm_auth.py

You'll need to create a Last.fm API application first:
    https://www.last.fm/api/account/create

The script will prompt for your API key and secret, then open a browser
for authorization. Credentials are saved to ~/.config/ytmusic/lastfm.json
"""

import hashlib
import json
import os
import sys
import urllib.parse
import urllib.request
import webbrowser

CONFIG_DIR = os.path.expanduser("~/.config/ytmusic")
CONFIG_FILE = os.path.join(CONFIG_DIR, "lastfm.json")
API_ROOT = "https://ws.audioscrobbler.com/2.0/"


def api_sig(params: dict, secret: str) -> str:
    """Generate Last.fm API signature."""
    sorted_params = "".join(f"{k}{v}" for k, v in sorted(params.items()))
    return hashlib.md5((sorted_params + secret).encode("utf-8")).hexdigest()


def api_call(params: dict, secret: str) -> dict:
    """Make a signed API call to Last.fm."""
    params["api_sig"] = api_sig(params, secret)
    params["format"] = "json"
    
    data = urllib.parse.urlencode(params).encode("utf-8")
    req = urllib.request.Request(API_ROOT, data=data, method="POST")
    
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def get_session_key(api_key: str, api_secret: str, token: str) -> str:
    """Exchange auth token for a session key."""
    params = {
        "method": "auth.getSession",
        "api_key": api_key,
        "token": token,
    }
    result = api_call(params, api_secret)
    
    if "error" in result:
        raise Exception(f"Last.fm API error: {result.get('message', 'Unknown error')}")
    
    return result["session"]["key"]


def main():
    print("=" * 60)
    print("Last.fm Scrobbler Setup for ytm.fish")
    print("=" * 60)
    print()
    
    # Check for existing config
    if os.path.exists(CONFIG_FILE):
        print(f"Existing config found at {CONFIG_FILE}")
        response = input("Overwrite? [y/N]: ").strip().lower()
        if response != "y":
            print("Aborted.")
            return
        print()
    
    print("First, create a Last.fm API application at:")
    print("  https://www.last.fm/api/account/create")
    print()
    print("Use any name (e.g., 'ytm-scrobbler') and leave callback URL blank.")
    print()
    
    api_key = input("Enter your API Key: ").strip()
    if not api_key:
        print("Error: API key is required")
        sys.exit(1)
    
    api_secret = input("Enter your Shared Secret: ").strip()
    if not api_secret:
        print("Error: Shared secret is required")
        sys.exit(1)
    
    print()
    print("Opening browser for authorization...")
    print("(If browser doesn't open, visit this URL manually)")
    print()
    
    auth_url = f"https://www.last.fm/api/auth/?api_key={api_key}"
    print(f"  {auth_url}")
    print()
    
    webbrowser.open(auth_url)
    
    print("After authorizing in your browser, press Enter to continue...")
    input()
    
    # Get token
    print("Getting authorization token...")
    try:
        params = {
            "method": "auth.getToken",
            "api_key": api_key,
        }
        result = api_call(params, api_secret)
        token = result["token"]
        
        # Need user to authorize this token
        auth_url_with_token = f"https://www.last.fm/api/auth/?api_key={api_key}&token={token}"
        print()
        print("Please authorize the application at this URL:")
        print(f"  {auth_url_with_token}")
        print()
        webbrowser.open(auth_url_with_token)
        
        print("After clicking 'Yes, allow access', press Enter...")
        input()
        
        # Exchange token for session
        print("Getting session key...")
        session_key = get_session_key(api_key, api_secret, token)
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
    
    # Save config
    os.makedirs(CONFIG_DIR, exist_ok=True)
    config = {
        "api_key": api_key,
        "api_secret": api_secret,
        "session_key": session_key,
    }
    
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f, indent=2)
    
    os.chmod(CONFIG_FILE, 0o600)  # Restrict permissions
    
    print()
    print("=" * 60)
    print("Setup complete!")
    print(f"Credentials saved to: {CONFIG_FILE}")
    print()
    print("Scrobbling will now work automatically when using ytm.")
    print("=" * 60)


if __name__ == "__main__":
    main()
