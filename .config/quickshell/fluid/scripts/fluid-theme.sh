#!/usr/bin/env bash
# Apply a wallpaper and recolour the desktop from it.
#
#   fluid-theme.sh <image> [mode] [scheme] [contrast] [lightness] [seed]
#
#   mode       dark | light                       (default: dark)
#   scheme     matugen --type, e.g. scheme-vibrant (default: scheme-tonal-spot)
#   contrast   -1 .. 1                            (default: 0)
#   lightness  e.g. -0.3 .. 0.3, darker..brighter (default: 0)
#   seed       "#rrggbb" to build the palette from instead of the image
#              (the theme picker passes the chosen wallpaper colour, hue-shifted)
#
# - remembers the wallpaper in ~/.local/state/fluid
# - writes the sway background for the next login / the waybar fallback
# - runs matugen, which writes colours for the shell, sway borders and wezterm
# - pushes the new border colours to the running sway session
set -u

img="${1:?usage: fluid-theme.sh <image> [mode] [scheme] [contrast] [lightness] [seed]}"
mode="${2:-dark}"
scheme="${3:-scheme-tonal-spot}"
contrast="${4:-0}"
lightness="${5:-0}"
seed="${6:-}"

here="$(dirname "$(realpath "$0")")"
state="${XDG_STATE_HOME:-$HOME/.local/state}/fluid"
mkdir -p "$state"
img="$(realpath "$img")"

shell_running() {
    [ -f "$state/qs.pid" ] && kill -0 "$(cat "$state/qs.pid")" 2>/dev/null
}

# Only touch the wallpaper when it actually changed (sliders re-run this a lot)
if [ "$(cat "$state/wallpaper" 2>/dev/null)" != "$img" ]; then
    printf '%s\n' "$img" > "$state/wallpaper"
    printf 'output * bg "%s" fill\n' "$img" > "$state/sway-wallpaper.conf"
    # While the shell runs it draws (and crossfades) the wallpaper itself.
    # Restarting swaybg would put it on top of the shell's wallpaper and turn
    # every later switch into a hard cut, so only do it without the shell.
    shell_running || swaymsg output '*' bg "$img" fill >/dev/null
fi

if command -v matugen >/dev/null; then
    cfg="$here/../matugen/config.toml"
    if [ "$mode" = "light" ]; then
        light_flag=(--lightness-light "$lightness")
    else
        light_flag=(--lightness-dark "$lightness")
    fi
    tweaks=(-c "$cfg" -m "$mode" -t "$scheme" --contrast "$contrast" "${light_flag[@]}")

    if [ -n "$seed" ]; then
        src=(color hex "$seed")
    else
        # --source-color-index skips matugen's interactive colour prompt
        src=(image "$img" --source-color-index 0)
    fi

    # Older matugen versions lack some tweak flags: fall back to the basics
    matugen "${src[@]}" "${tweaks[@]}" >/dev/null 2>&1 \
        || matugen "${src[@]}" -c "$cfg" -m "$mode" >/dev/null 2>&1 \
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

# Tell the running shell to re-read colors.json (no-op if it isn't running)
qs -c fluid ipc call fluid reloadTheme >/dev/null 2>&1 \
    || quickshell -c fluid ipc call fluid reloadTheme >/dev/null 2>&1 || true
