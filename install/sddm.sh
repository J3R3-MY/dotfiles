#!/usr/bin/env bash
# Install the fluid SDDM login theme with one of your wallpapers.
#
#   install/sddm.sh                 pick a wallpaper (list), or use the current one
#   install/sddm.sh <image>         use this image
#
# Everything is copied to /usr/share/sddm/themes/fluid, so the login screen
# keeps working if the repo moves or is deleted. Re-run to change it.
set -u
source "$(dirname "$(realpath "$0")")/lib.sh"
LOG="${LOG:-$HOME/sddm-theme-$(date +%Y%m%d-%H%M%S).log}"
sudo -v || exit 1
do_sddm_theme "${1:-}"
