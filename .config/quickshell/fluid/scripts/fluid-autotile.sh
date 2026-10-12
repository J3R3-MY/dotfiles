#!/usr/bin/env bash
# Hyprland-style "dwindle" tiling for sway/swayfx: whenever a tiled window
# gets focus, sway is told to split it along its longer side, so the next
# window opens beside it (wide) or below it (tall); near-square windows (up to
# 10% taller than wide) count as wide, so ties go to the right. Tabbed/stacked containers
# and floating windows are left alone. Same idea as the `autotiling` script,
# without its Python dependency.
#
# The size is read from a fresh tree, not from the event: when a neighbour
# closes, the remaining window gets focus before sway has grown it, so the
# event still shows the old (tall) size and the next window opened below.
swaymsg -t subscribe -m '["window"]' \
| jq --unbuffered -r 'select(.change == "focus" or .change == "new" or .change == "close") | .change' \
| while read -r _; do
    read -r id split parent < <(swaymsg -t get_tree | jq -r 'first(.. | objects
        | select(any(.nodes[]?; .focused and .type == "con")) | .layout as $l | .nodes[] | select(.focused)
        | "\(.id) \(if .rect.width * 1.1 >= .rect.height then "splith" else "splitv" end) \($l)") // empty')
    [ -n "${id:-}" ] || continue                 # floating or nothing focused
    case "$parent" in tabbed|stacked) continue ;; esac
    swaymsg "[con_id=$id] $split" >/dev/null
done
