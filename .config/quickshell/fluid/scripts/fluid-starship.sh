#!/usr/bin/env bash
# Build ~/.local/state/fluid/starship.toml: your ~/.config/starship.toml with
# its palette switched to the one matugen generated from the wallpaper.
# Only used on Linux (.zsh_linux sets STARSHIP_CONFIG); macOS keeps reading
# ~/.config/starship.toml with its own palette. Run by fluid-theme.sh and at
# shell start, so edits to starship.toml are picked up too.
state="${XDG_STATE_HOME:-$HOME/.local/state}/fluid"
src="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
palette="$state/starship-palette.toml"
[ -f "$src" ] && [ -f "$palette" ] || exit 0

tmp="$state/starship.toml.tmp"
{
    # point the palette selector at "fluid", keep everything else as is
    sed 's/^palette *= *".*"/palette = "fluid"/' "$src"
    echo
    cat "$palette"
} > "$tmp" && mv "$tmp" "$state/starship.toml"
