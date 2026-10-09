#!/usr/bin/env bash
# Apply a wallpaper and recolour the desktop from it.
#
#   fluid-theme.sh <image> [dark|light]
#
# - remembers the wallpaper/mode in ~/.local/state/fluid
# - sets it as the sway background (swaybg), so it also works without the shell
# - runs matugen, which writes colours for the shell, sway borders and wezterm
# - pushes the new border colours to the running sway session
set -u

img="${1:?usage: fluid-theme.sh <image> [dark|light]}"
here="$(dirname "$(realpath "$0")")"
state="${XDG_STATE_HOME:-$HOME/.local/state}/fluid"
mkdir -p "$state"

mode="${2:-$(cat "$state/mode" 2>/dev/null || echo dark)}"
img="$(realpath "$img")"

printf '%s\n' "$img" > "$state/wallpaper"
printf '%s\n' "$mode" > "$state/mode"

# Persist for the next sway start (included by fluid.conf)
printf 'output * bg "%s" fill\n' "$img" > "$state/sway-wallpaper.conf"

if pgrep -f -- '(qs|quickshell) -c fluid$' >/dev/null; then
    # The shell crossfades the wallpaper itself; update swaybg underneath once
    # the fade is done so it doesn't cut the animation short.
    ( sleep 1.5; swaymsg output '*' bg "$img" fill >/dev/null ) &
else
    swaymsg output '*' bg "$img" fill >/dev/null
fi

if command -v matugen >/dev/null; then
    cfg="$here/../matugen/config.toml"
    # --source-color-index avoids matugen's interactive colour prompt;
    # retry without it for older matugen versions that don't know the flag.
    matugen image "$img" -c "$cfg" -m "$mode" --source-color-index 0 >/dev/null 2>&1 \
        || matugen image "$img" -c "$cfg" -m "$mode" >/dev/null 2>&1 \
        || echo "fluid-theme: matugen failed" >&2
else
    echo "fluid-theme: matugen not installed, colours unchanged" >&2
fi

# Live-update sway border colours
if [ -f "$state/sway-colors.conf" ]; then
    grep '^client\.' "$state/sway-colors.conf" | while IFS= read -r line; do
        swaymsg "$line" >/dev/null
    done
fi

# Tell the running shell to re-read colors.json / wallpaper (no-op if it isn't running)
qs -c fluid ipc call fluid reloadTheme >/dev/null 2>&1 \
    || quickshell -c fluid ipc call fluid reloadTheme >/dev/null 2>&1 || true

wait
