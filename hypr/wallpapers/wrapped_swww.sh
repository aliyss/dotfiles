#!/bin/bash

# Random wallpaper switcher for light/day and dark/night themes
# Usage: ./wallpaper.sh <light_images_dir> <dark_images_dir>

if [[ $# -lt 2 ]] || [[ ! -d $1 ]] || [[ ! -d $2 ]]; then
    echo "Usage:"
    echo "  $0 <light_images_dir> <dark_images_dir>"
    exit 1
fi

LIGHT_DIR="$1"
DARK_DIR="$2"

# Transition settings for swww
export SWWW_TRANSITION_FPS=60
export SWWW_TRANSITION_STEP=2

# Interval between wallpapers (seconds)
INTERVAL=60

# Define day/night hours
DAY_START=7    # 07:00
NIGHT_START=19  # 19:00

while true; do
    HOUR=$(date +%H)

    # Pick directory based on time of day
    if (( HOUR >= DAY_START && HOUR < NIGHT_START )); then
        IMG_DIR="$LIGHT_DIR"
    else
        IMG_DIR="$DARK_DIR"
    fi

    # Shuffle and cycle images
    find "$IMG_DIR" -type f \
        | while read -r img; do
            echo "$((RANDOM % 1000)):$img"
        done \
        | sort -n | cut -d':' -f2- \
        | while read -r img; do
            swww img "$img"
            echo "Set wallpaper: $img"
            sleep $INTERVAL
        done
done
