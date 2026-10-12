#!/bin/bash
# macOS: link the shared + Mac dotfiles into ~ (re-runnable). The repo holds
# both systems; Linux-only configs are skipped here, macOS-only ones are
# skipped by the Linux installer (install/lib.sh, do_dotfiles).
set -e
cd "$(dirname "$0")"
command -v stow >/dev/null || { echo "stow is missing: brew install stow"; exit 1; }
# stow links everything in the folder, tracked by git or not: stop on stray files
stray=$(git ls-files --others --exclude-standard)
if [ -n "$stray" ]; then
    printf 'Files in the repo that git does not track (stow would link them too):\n%s\n' "$stray"
    read -rp "Link anyway? [y/N] " a
    [[ "$a" =~ ^[yY] ]] || exit 1
fi
# a real ~/.config makes stow link per app instead of the whole folder
mkdir -p "$HOME/.config"
stow -v -t "$HOME" \
    --ignore='\.zsh_linux' \
    --ignore='\.config/(sway|swaylock|waybar|wofi|dunst|pipewire|quickshell|scripts)' \
    .
