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

supervisor_pid="$state/supervisor.pid"
qs_pid="$state/qs.pid"

# Stop by PID (Quickshell's process title doesn't reliably match its command
# line, which is why matching on "qs -c fluid" missed it), then ask Quickshell
# itself. The supervisor goes first so it can't restart the shell.
stop_fluid() {
    [ -f "$supervisor_pid" ] && kill "$(cat "$supervisor_pid")" 2>/dev/null
    [ -f "$qs_pid" ] && kill "$(cat "$qs_pid")" 2>/dev/null
    rm -f "$supervisor_pid" "$qs_pid"
    [ -n "$qs_bin" ] && "$qs_bin" kill -c fluid >/dev/null 2>&1
    return 0
}
stop_classic() { pkill -x waybar 2>/dev/null; pkill -x dunst 2>/dev/null; return 0; }

start_classic() {
    stop_fluid
    # The shell drew the wallpaper itself; hand it back to swaybg
    wp="$(cat "$state/wallpaper" 2>/dev/null)"
    [ -n "$wp" ] && [ -f "$wp" ] && swaymsg output '*' bg "$wp" fill >/dev/null 2>&1
    pgrep -x waybar >/dev/null || setsid -f waybar >/dev/null 2>&1
    pgrep -x dunst  >/dev/null || setsid -f dunst  >/dev/null 2>&1
    # password prompts: the shell's island did them, polkit-gnome takes over again
    pgrep -x polkit-gnome-au >/dev/null \
        || setsid -f /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 >/dev/null 2>&1
}

if [ "$mode" != "fluid" ] || [ -z "$qs_bin" ]; then
    [ -z "$qs_bin" ] && [ "$mode" = "fluid" ] && echo "fluid: quickshell not installed, using waybar" >&2
    start_classic
    exit 0
fi

stop_classic
stop_fluid
sleep 0.3

# Supervise: restart on crash, but give up (and fall back to waybar) if it
# dies within 10s three times in a row.
(
    echo "$BASHPID" > "$supervisor_pid"
    fails=0
    while [ "$(cat "$state/shell" 2>/dev/null || echo fluid)" = "fluid" ]; do
        started=$(date +%s)
        "$qs_bin" -c fluid >>"$state/fluid.log" 2>&1 &
        echo $! > "$qs_pid"
        wait $!
        code=$?
        # Switched to classic meanwhile: stop supervising
        [ "$(cat "$state/shell" 2>/dev/null)" != "fluid" ] && exit 0
        if [ $(( $(date +%s) - started )) -lt 10 ]; then
            fails=$((fails + 1))
        else
            fails=0
        fi
        if [ "$fails" -ge 3 ]; then
            notify-send -u critical "fluid shell keeps crashing" "Falling back to waybar. Log: $state/fluid.log" 2>/dev/null
            echo classic > "$state/shell"
            rm -f "$supervisor_pid"     # don't let start_classic kill this subshell
            start_classic
            exit 1
        fi
        echo "fluid: shell exited with $code, restarting" >>"$state/fluid.log"
        sleep 1
    done
) >/dev/null 2>&1 &
disown
