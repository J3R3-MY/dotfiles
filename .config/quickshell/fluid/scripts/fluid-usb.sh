#!/usr/bin/env bash
# USBGuard keeps newly plugged-in USB devices blocked. This tells you when it
# blocked one; "Allow" asks for your password (the island prompt) and makes
# USBGuard remember the device. Started by sway (fluid.conf); no-op without
# USBGuard. Your user may only list/watch devices (install/lib.sh), allowing
# needs the password.
command -v usbguard >/dev/null || exit 0
declare -A told
check() {
    # e.g.: 12: block id 0781:5581 serial "..." name "Ultra" hash "..." via-port "3-2" ...
    while read -r line; do
        id=${line%%:*}
        [ -n "$id" ] && [ -z "${told[$id]:-}" ] || continue
        told[$id]=1
        name=$(sed -n 's/.* name "\([^"]*\)".*/\1/p' <<<"$line")
        vid=$(awk '{print $4}' <<<"$line")
        ( a=$(notify-send -a USBGuard -u critical -A allow=Allow "USB device blocked" "${name:-unknown device} ($vid)")
          [ "$a" = allow ] && pkexec usbguard allow-device --permanent "$id" ) >/dev/null 2>&1 &
    done < <(usbguard list-devices --blocked 2>/dev/null)
}
while :; do
    check
    while read -r ev; do
        case "$ev" in *Insert*|*PolicyChanged*) sleep 0.3; check ;; esac
    done < <(usbguard watch 2>/dev/null)
    sleep 5      # daemon restarted or not running yet
done
