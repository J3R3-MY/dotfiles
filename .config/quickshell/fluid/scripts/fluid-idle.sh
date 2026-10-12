#!/usr/bin/env bash
# Idle like a Mac, called by swayidle (see .config/sway/config):
#   fluid-idle.sh at <seconds idle>   escalate to whatever is due by now
#   fluid-idle.sh wake                input again: full brightness, screens on
#
#                 dim      screen off + lock   sleep
#   battery       2:30     3 min               10 min
#   charger       9:30     10 min              never (lid open)
#
# swayidle can't tell battery from charger, so it calls "at" at every
# threshold and this script decides. Each step is idempotent and anything
# already due is caught up, e.g. unplugging after 5 min on the charger turns
# the screen off at the next check. Sleep is suspend-then-hibernate
# (fluid-sleep.sh).
#
# Audio, as on a Mac: playing sound (music, video) only keeps it from
# sleeping, the screen still goes off; a microphone in use (a call) also keeps
# the screen on. Once it has been quiet for 30 s the step that was held back
# runs. Full-screen video in browsers inhibits idle through sway already.
#
# Keep awake (control center tile): while $run/awake exists nothing happens
# on idle at all; closing the lid still sleeps.
dir="$(dirname "$(realpath "$0")")"
run="${XDG_RUNTIME_DIR:-/tmp}/fluid-idle"
mkdir -p "$run"

on_ac() {
    local s
    for s in /sys/class/power_supply/A*/online; do
        [ "$(cat "$s" 2>/dev/null)" = 1 ] && return 0
    done
    # no battery at all (desktop) counts as the charger
    ! ls /sys/class/power_supply/BAT* >/dev/null 2>&1
}

# PipeWire/Pulse devices that are streaming right now
playing()   { pactl list short sinks 2>/dev/null | awk '$NF == "RUNNING"' | grep -q .; }
recording() { pactl list short sources 2>/dev/null | grep -v '\.monitor' | awk '$NF == "RUNNING"' | grep -q .; }
audio()     { playing || recording; }

# Re-run "at" (with the furthest step held back so far) after <check> has been
# false for 30 s. "wake" cancels it.
hold() {
    local check=$1 t=$2
    [ "$t" -gt "$(cat "$run/held" 2>/dev/null || echo 0)" ] && echo "$t" > "$run/held"
    [ -e "$run/waiter" ] && kill -0 "$(cat "$run/waiter")" 2>/dev/null && return
    (
        quiet=0
        while [ "$quiet" -lt 2 ]; do
            sleep 15
            if "$check"; then quiet=0; else quiet=$((quiet + 1)); fi
        done
        t=$(cat "$run/held" 2>/dev/null || echo 0)
        rm -f "$run/waiter" "$run/held"
        exec "$0" at "$t"
    ) &
    echo $! > "$run/waiter"
}

# The OSD ignores brightness changes while $run/dim exists
dim() {
    [ -e "$run/dim" ] && return
    command -v brightnessctl >/dev/null || return
    local cur target i
    cur=$(brightnessctl -c backlight g 2>/dev/null) || return
    rm -f "$run/woke"
    echo "$cur" > "$run/dim"
    sleep 0.6   # let the shell notice before the brightness moves
    target=$(( cur * 35 / 100 )); [ "$target" -lt 1 ] && target=1
    # fade over ~0.6 s like macOS
    for i in 1 2 3 4 5 6 7 8; do
        [ -e "$run/woke" ] && break
        brightnessctl -q -c backlight set $(( cur - (cur - target) * i / 8 ))
        sleep 0.075
    done
    # input arrived mid-fade: make sure the last step didn't win
    [ -e "$run/woke" ] && brightnessctl -q -c backlight set "$cur"
}

undim() {
    [ -e "$run/dim" ] || return
    touch "$run/woke"
    brightnessctl -q -c backlight set "$(cat "$run/dim")"
    # keep the OSD quiet until the brightness poll has seen the restore
    ( sleep 0.6; rm -f "$run/dim" ) &
}

screen_off() {
    [ -e "$run/off" ] && return
    touch "$run/off"
    "$dir/fluid-lock.sh"
    swaymsg -q 'output * power off'
}

case "$1" in
    at)
        [ -e "$run/awake" ] && exit 0
        t=${2:-0}
        if on_ac; then d=570 o=600 s=
        else           d=150 o=180 s=600; fi
        [ "$t" -lt "$d" ] && exit 0
        if recording; then hold recording "$t"; exit 0; fi
        if [ -n "$s" ] && [ "$t" -ge "$s" ]; then
            screen_off
            if audio; then hold audio "$t"; else exec "$dir/fluid-sleep.sh"; fi
        elif [ "$t" -ge "$o" ]; then screen_off
        else dim
        fi ;;
    wake)
        if [ -e "$run/waiter" ]; then
            kill "$(cat "$run/waiter")" 2>/dev/null
            rm -f "$run/waiter" "$run/held"
        fi
        if [ -e "$run/off" ]; then
            rm -f "$run/off"
            swaymsg -q 'output * power on'
        fi
        undim ;;
    *)
        echo "usage: $0 at <seconds> | wake" >&2; exit 1 ;;
esac
