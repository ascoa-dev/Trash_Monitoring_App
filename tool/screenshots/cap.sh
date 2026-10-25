#!/usr/bin/env bash
# Usage: cap.sh <device> <lang> <name>  — saves the emulator screen to store_listings/raw/<device>/<lang>/<name>.png
set -e
dir="$(dirname "$0")/../../store_listings/raw/$1/$2"; mkdir -p "$dir"
adb exec-out screencap -p > "$dir/$3.png"
echo "$dir/$3.png"
