#!/usr/bin/env bash
# Lock the screen: the fluid lock screen if the shell is running, swaylock
# otherwise (so this is safe to bind even in waybar mode).
state="${XDG_STATE_HOME:-$HOME/.local/state}/fluid"
if [ -f "$state/qs.pid" ] && kill -0 "$(cat "$state/qs.pid")" 2>/dev/null \
    && { qs -c fluid ipc call fluid lock || quickshell -c fluid ipc call fluid lock; } >/dev/null 2>&1; then
    # give the lock surface a moment before e.g. suspend continues
    sleep 0.5
else
    exec swaylock -f
fi
