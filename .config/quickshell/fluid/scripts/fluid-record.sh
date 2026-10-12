#!/usr/bin/env bash
# Screen recording (wf-recorder), no audio. Calling it while recording stops.
#
#   fluid-record.sh          whole focused screen   (control center tile)
#   fluid-record.sh area     drag an area first     ($mod+Shift+r)
#   fluid-record.sh stop
#
# Saved to ~/Videos/Recording <date>.mp4. The island shows a red dot with the
# time while recording (told over IPC); clicking it stops.
set -u
command -v wf-recorder >/dev/null || { notify-send -a Recorder "wf-recorder isn't installed"; exit 1; }
ipc() { qs -c fluid ipc call fluid recording "$1" >/dev/null 2>&1; }

if pgrep -x wf-recorder >/dev/null || [ "${1:-}" = stop ]; then
    pkill -INT -x wf-recorder        # INT lets it finish the file
    exit 0
fi

dir=$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Videos")
mkdir -p "$dir"
file="$dir/Recording $(date '+%Y-%m-%d %H.%M.%S').mp4"
if [ "${1:-}" = area ]; then
    geo=$(slurp) || exit 0
    set -- -g "$geo"
else
    out=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
    set -- -o "$out"
fi

ipc true
wf-recorder "$@" -f "$file" >/dev/null 2>&1
ipc false
[ -s "$file" ] && notify-send -a Recorder "Recording saved" "$(basename "$file")"
