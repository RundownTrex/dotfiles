#!/bin/bash

set -e

echo "=== Arch Cache Cleaner ==="

# Clear pacman package cache
echo "Clearing pacman cache..."
sudo rm -rf /var/cache/pacman/pkg/*

# Clear yay cache
if command -v yay >/dev/null 2>&1; then
    echo "Clearing yay cache..."
    yay -Sc --noconfirm
fi

# Remove yay build directory
if [ -d "$HOME/.cache/yay" ]; then
    echo "Removing yay build files..."
    rm -rf "$HOME/.cache/yay"/*
fi

echo "=== Cleanup complete ==="
