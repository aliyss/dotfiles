#!/bin/bash

# --- Check argument ---
if [ -z "$1" ]; then
    echo "Usage: $0 <command> [args...]"
    exit 1
fi

# --- Get focused workspace ID ---
focused_ws_id=$(niri msg --json workspaces | jq -r '.[] | select(.is_focused == true) | .id')

if [ -z "$focused_ws_id" ] || [ "$focused_ws_id" = "null" ]; then
    echo "Error: Could not determine focused workspace."
    exit 1
fi

# --- Count windows before launching ---
initial_count=$(niri msg --json windows | jq "[.[] | select(.workspace_id == $focused_ws_id)] | length")
initial_count=${initial_count:-0}

# --- Launch command in background ---
"$@" &

# --- Wait for new window to appear ---
timeout=50   # 50 × 0.1s = 5 seconds
sleep_time=0.1

for ((i=0; i<timeout; i++)); do
    current_count=$(niri msg --json windows | jq "[.[] | select(.workspace_id == $focused_ws_id)] | length")
    current_count=${current_count:-0}

    # If a new window appeared
    if (( current_count > initial_count )); then
        if (( current_count < 4 )); then
            niri msg action center-visible-columns
        else
            niri msg action center-visible-columns
            # niri msg action center-window
        fi
        exit 0
    fi

    sleep "$sleep_time"
done

echo "Warning: No new window detected after 5 seconds."
