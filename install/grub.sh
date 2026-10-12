#!/usr/bin/env bash
# Install (or update) the minegrub boot menu theme from grub/ in the repo.
# Copies it to /boot/grub/themes/minegrub, sets GRUB_THEME, runs grub-mkconfig.
set -u
source "$(dirname "$(realpath "$0")")/lib.sh"
LOG="${LOG:-$HOME/grub-theme-$(date +%Y%m%d-%H%M%S).log}"
sudo -v || exit 1
do_grub_theme
echo "Log: $LOG"
