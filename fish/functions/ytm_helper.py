#!/usr/bin/env python3
"""Helper: query mpv's current playlist position via IPC socket."""
import socket, json, sys

def get_property(sock_path, prop):
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.settimeout(2)
        s.connect(sock_path)
        s.sendall(json.dumps({"command": ["get_property", prop]}).encode() + b"\n")
        data = s.recv(4096)
        s.close()
        for line in data.decode().strip().split("\n"):
            r = json.loads(line)
            if "data" in r:
                return r["data"]
    except Exception:
        pass
    return -1

if __name__ == "__main__":
    sock = sys.argv[1]
    prop = sys.argv[2] if len(sys.argv) > 2 else "playlist-pos"
    print(get_property(sock, prop))
