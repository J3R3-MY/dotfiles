#!/usr/bin/env bash
# Remove the EndeavourOS default apps this setup replaces (list: EOS_UNUSED
# in lib.sh). Safe to re-run; pacman only removes what's installed.
set -u
source "$(dirname "$(realpath "$0")")/lib.sh"
LOG="${LOG:-$HOME/cleanup-$(date +%Y%m%d-%H%M%S).log}"
sudo -v || exit 1
do_cleanup
echo "Log: $LOG"
