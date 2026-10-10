#!/usr/bin/env bash
# Set up (or re-check) hibernation on its own: swap file >= RAM, resume in the
# initramfs, lid switch -> hibernate. Reboot afterwards.
set -u
source "$(dirname "$(realpath "$0")")/lib.sh"
LOG="$HOME/hibernate-setup-$(date +%Y%m%d-%H%M%S).log"
sudo -v || exit 1
do_hibernate
echo "Log: $LOG"
