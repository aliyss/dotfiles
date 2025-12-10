#!/usr/bin/env bash
set -e

SERVICE="keyd.service"

if systemctl is-active --quiet "$SERVICE"; then
  setxkbmap us
  sudo systemctl stop "$SERVICE"
  hyprctl notify -1 10000 "rgb(ff1ea3)" "Enabled Gaming!"
else
  echo "Enabling keyd..."
  sudo systemctl start "$SERVICE"
  hyprctl notify -1 10000 "rgb(ff1ea3)" "Enabled Desktop!"
fi
