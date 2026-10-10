#!/usr/bin/env bash
# Hyprland-style "dwindle" tiling for sway/swayfx: whenever a tiled window
# gets focus, sway is told to split it along its longer side, so the next
# window opens beside it (wide) or below it (tall). Tabbed/stacked containers
# and floating windows are left alone. Same idea as the `autotiling` script,
# without its Python dependency.
swaymsg -t subscribe -m '["window"]' \
| jq --unbuffered -r 'select(.change == "focus" and .container.type == "con") | .container | "\(.id) \(if .rect.width > .rect.height then "splith" else "splitv" end)"' \
| while read -r id split; do
    parent=$(swaymsg -t get_tree | jq -r --argjson id "$id" \
        'first(.. | objects | select(any(.nodes[]?; .id == $id))) | .layout')
    case "$parent" in tabbed|stacked) continue ;; esac
    swaymsg "[con_id=$id] $split" >/dev/null
done
