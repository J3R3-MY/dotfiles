#!/usr/bin/env bash
# Starts the desktop shell for sway.
#
#   fluid-launch.sh            start whatever mode was last chosen (default: fluid)
#   fluid-launch.sh fluid      switch to the Quickshell "fluid" shell
#   fluid-launch.sh classic    switch back to the old waybar + dunst setup
#
# Downwards compatible by design: if Quickshell isn't installed, or the shell
# crashes right after starting, waybar + dunst are started exactly as before.

state="${XDG_STATE_HOME:-$HOME/.local/state}/fluid"
mkdir -p "$state"

if [ -n "$1" ]; then
    echo "$1" > "$state/shell"
fi
mode="$(cat "$state/shell" 2>/dev/null || echo fluid)"

qs_bin="$(command -v qs || command -v quickshell)"

pidfile="$state/supervisor.pid"
shell_re='(qs|quickshell) -c fluid$'

# Kill the supervisor first so it doesn't restart the shell we're stopping
stop_fluid() {
    [ -f "$pidfile" ] && kill "$(cat "$pidfile")" 2>/dev/null
    rm -f "$pidfile"
    pkill -f -- "$shell_re" 2>/dev/null
}
stop_classic() { pkill -x waybar 2>/dev/null; pkill -x dunst 2>/dev/null; }

start_classic() {
    stop_fluid
    pgrep -x waybar >/dev/null || waybar >/dev/null 2>&1 &
    pgrep -x dunst  >/dev/null || dunst  >/dev/null 2>&1 &
}

if [ "$mode" != "fluid" ] || [ -z "$qs_bin" ]; then
    [ -z "$qs_bin" ] && [ "$mode" = "fluid" ] && echo "fluid: quickshell not installed, using waybar" >&2
    start_classic
    exit 0
fi

stop_classic
stop_fluid
sleep 0.2

# Supervise: restart on crash, but give up (and fall back to waybar) if it
# dies within 10s three times in a row.
(
    echo "$BASHPID" > "$pidfile"
    fails=0
    while [ "$(cat "$state/shell" 2>/dev/null || echo fluid)" = "fluid" ]; do
        started=$(date +%s)
        "$qs_bin" -c fluid >>"$state/fluid.log" 2>&1
        code=$?
        # A clean exit (e.g. `fluid-launch.sh classic` killing us) ends supervision
        [ "$(cat "$state/shell" 2>/dev/null)" != "fluid" ] && exit 0
        if [ $(( $(date +%s) - started )) -lt 10 ]; then
            fails=$((fails + 1))
        else
            fails=0
        fi
        if [ "$fails" -ge 3 ]; then
            notify-send -u critical "fluid shell keeps crashing" "Falling back to waybar. Log: $state/fluid.log" 2>/dev/null
            start_classic
            exit 1
        fi
        echo "fluid: shell exited with $code, restarting" >>"$state/fluid.log"
        sleep 1
    done
) >/dev/null 2>&1 &
disown
