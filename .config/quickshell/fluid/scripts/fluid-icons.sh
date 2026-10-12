#!/usr/bin/env bash
# GTK icons (Thunar, file dialogs, launcher) in the theme's accent colour, like
# the bar: a recoloured copy of yet-another-monochrome-icon-set named
# "fluid-mono". Its icons are drawn in one CSS colour (.ColorScheme-Text), so
# recolouring is a text replace. Run by fluid-theme.sh; no-op without the
# icon set or when the colour didn't change.
set -u

icons="$HOME/.local/share/icons"
src="$icons/yet-another-monochrome-icon-set" dest="$icons/fluid-mono"
state="${XDG_STATE_HOME:-$HOME/.local/state}/fluid"
[ -f "$src/index.theme" ] || exit 0

# the theme sliders re-run this a lot: one at a time
exec 9>"$state/icons.lock"
flock 9

color=$(jq -r '.accent // empty' "$state/colors.json" 2>/dev/null)
[ -n "$color" ] || exit 0
[ -d "$dest" ] && [ "$color" = "$(cat "$state/icons-color" 2>/dev/null)" ] && exit 0

# Build next to it, then swap (cp is near-instant on btrfs: reflinks)
rm -rf "$dest.new"
cp -a "$src" "$dest.new" && rm -rf "$dest.new/.git" || exit 1
find "$dest.new" -name '*.svg' -type f -print0 \
    | xargs -0 sed -i "s/ColorScheme-Text {color:#[0-9a-fA-F]*}/ColorScheme-Text {color:$color}/"
sed -i 's/^Name=.*/Name=fluid-mono/' "$dest.new/index.theme"
# names the set lacks would fall through to the coloured Papirus icons
for d in scalable scalable-outlined; do
    ln -sfn text-x-script.svg "$dest.new/mimetypes/$d/text-x-shellscript.svg"
done
gtk-update-icon-cache -q -f "$dest.new" 2>/dev/null
rm -rf "$dest" && mv "$dest.new" "$dest"
printf '%s\n' "$color" > "$state/icons-color"

# GTK apps only reload icons when the theme name changes
if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface icon-theme yet-another-monochrome-icon-set
    gsettings set org.gnome.desktop.interface icon-theme fluid-mono
fi
