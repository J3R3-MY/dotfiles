#!/usr/bin/env bash
# $mod+Shift+o: every window solid, or back to the see-through rules in
# ~/.config/sway/fluid.conf ("for_window [...] opacity N"). WezTerm follows
# via ~/.local/state/fluid/opacity (.wezterm.lua watches it).
set -u
state="${XDG_STATE_HOME:-$HOME/.local/state}/fluid"
mkdir -p "$state"

if [ "$(cat "$state/opacity" 2>/dev/null)" = solid ]; then
    echo normal > "$state/opacity"
    cmds="[all] opacity 1"
    while read -r crit op val; do cmds="$cmds; $crit $op $val"; done < <(
        sed -n 's/^for_window \(\[[^]]*\]\) \(opacity\) \([0-9.]*\)$/\1 \2 \3/p' "$HOME/.config/sway/fluid.conf")
    swaymsg "$cmds" >/dev/null
else
    echo solid > "$state/opacity"
    swaymsg '[all] opacity 1' >/dev/null
fi
