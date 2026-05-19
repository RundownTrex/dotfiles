#!/bin/bash

dns=$(nmcli dev show | grep 'IP4.DNS' | awk '{print $2}' | head -n1)

if [ -n "$dns" ]; then
    echo "$dns"
else
    echo "No IPv4 DNS found" >&2
    exit 1
fi
