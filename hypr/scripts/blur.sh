#!/bin/bash

PREVIOUS_WINDOW=""

function handle {
  if [[ ${1:0:14} == "activewindowv2" ]]; then
      # hyprctl setprop "address:0x$PREVIOUS_WINDOW" dimaround 0
      # hyprctl setprop "address:0x${1:16:7}" dimaround 1
      PREVIOUS_WINDOW=${1:16:7}
  fi
}

socat - "UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done
