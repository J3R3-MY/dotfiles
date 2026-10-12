#!/usr/bin/env bash
# Install the fluid SDDM login theme: the lock screen design with the current
# wallpaper and colours (fluid-theme.sh keeps those in step afterwards).
#
# Everything is copied to /usr/share/sddm/themes/fluid, so the login screen
# keeps working if the repo moves or is deleted. Re-run after changing the QML.
set -u
source "$(dirname "$(realpath "$0")")/lib.sh"
LOG="${LOG:-$HOME/sddm-theme-$(date +%Y%m%d-%H%M%S).log}"
sudo -v || exit 1
do_sddm_theme
