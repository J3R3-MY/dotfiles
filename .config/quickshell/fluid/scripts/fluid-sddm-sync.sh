#!/usr/bin/env bash
# Keep the SDDM login screen in step with the desktop: copies the current
# wallpaper (scaled-down JPEG) and colours into the fluid SDDM theme.
#
#   fluid-sddm-sync.sh [image]     default: the current wallpaper
#
# install/lib.sh makes background.jpg and theme.conf yours (the QML stays
# root's), so fluid-theme.sh can run this without sudo. No-op otherwise.
set -u

dest=/usr/share/sddm/themes/fluid
state="${XDG_STATE_HOME:-$HOME/.local/state}/fluid"
[ -w "$dest/theme.conf" ] && [ -w "$dest/background.jpg" ] || exit 0

# Wallpaper: only re-encode when it changed (the theme sliders re-run this a lot)
img="${1:-$(cat "$state/wallpaper" 2>/dev/null)}"
if [ -f "$img" ] && [ "$img" != "$(cat "$state/sddm-wallpaper" 2>/dev/null)" ]; then
    if command -v magick >/dev/null; then
        magick "$img[0]" -resize '2560x2560>' -quality 90 "$state/sddm-bg.jpg" && cat "$state/sddm-bg.jpg" > "$dest/background.jpg"
        rm -f "$state/sddm-bg.jpg"
    else
        cat "$img" > "$dest/background.jpg"
    fi
    printf '%s\n' "$img" > "$state/sddm-wallpaper"
fi

# Colours from the current fluid theme (matugen), else the waybar defaults
c="$state/colors.json" accent="#c4bca4" on="#0e0c0c" panel="#0e0c0c" dim="#a7a097"
if [ -s "$c" ] && command -v jq >/dev/null; then
    accent=$(jq -r '.clock // "#c4bca4"' "$c"); on=$(jq -r '.onPill // "#0e0c0c"' "$c")
    panel=$(jq -r '.bg // "#0e0c0c"' "$c"); dim=$(jq -r '.fgDim // "#a7a097"' "$c")
fi
printf '[General]\nbackground=background.jpg\naccent=%s\nonAccent=%s\npanel=%s\nfgDim=%s\n' \
    "$accent" "$on" "$panel" "$dim" > "$dest/theme.conf"
