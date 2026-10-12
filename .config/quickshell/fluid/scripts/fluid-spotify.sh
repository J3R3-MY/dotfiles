#!/usr/bin/env bash
# Spotify ($mod+Shift+m, media view, Control center) lives on its own
# workspace "m" (sway config moves the window there): go to it, starting the
# official app if it isn't running; pressing again from there goes back.
ws=m
if [ "$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused).name')" = "$ws" ]; then
    exec swaymsg -q workspace back_and_forth
fi
swaymsg -q workspace "$ws"
pgrep -x spotify >/dev/null || exec spotify-launcher
