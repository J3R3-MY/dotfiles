#!/usr/bin/env bash
# ----------------------------------------------------------
# Sway + fluid Quickshell shell, for a fresh EndeavourOS "No Desktop" install.
#
#   git clone <repo> ~/dotfiles && ~/dotfiles/install-sway-fluid.sh
#
# Everything install-sway.sh does, plus Quickshell and matugen. waybar and
# dunst are still installed: they're the automatic fallback, and
# $mod+Alt+w / $mod+Alt+q switch between the two at any time.
# ----------------------------------------------------------

set -u
source "$(dirname "$(realpath "$0")")/install/lib.sh"

banner "Sway + fluid shell (Quickshell) setup for EndeavourOS (no desktop)."
confirm "DO YOU WANT TO START THE INSTALLATION NOW?" || { echo ":: Installation canceled"; exit 0; }

preflight
do_update
do_packages yes
do_services
do_login_manager
do_hibernate
do_dotfiles
do_user_setup
do_shell_mode fluid
summary
echo "Fluid keys: \$mod+p launcher · \$mod+t theme · \$mod+i control center · \$mod+v clipboard"
