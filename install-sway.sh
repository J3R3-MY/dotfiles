#!/usr/bin/env bash
# ----------------------------------------------------------
# Sway setup (waybar + dunst), for a fresh EndeavourOS "No Desktop" install.
#
#   git clone <repo> ~/dotfiles && ~/dotfiles/install-sway.sh
#
# Installs everything the sway config and the rest of the dotfiles use,
# enables the services, links the dotfiles and sets up SDDM. Reboot after.
# Want the Quickshell version instead? Use install-sway-fluid.sh.
# ----------------------------------------------------------

set -u
source "$(dirname "$(realpath "$0")")/install/lib.sh"

banner "Sway + waybar setup for EndeavourOS (no desktop)."
confirm "DO YOU WANT TO START THE INSTALLATION NOW?" || { echo ":: Installation canceled"; exit 0; }

preflight
do_update
do_packages no
do_services
do_login_manager
do_hibernate
do_dotfiles
do_user_setup
do_shell_mode classic
summary
