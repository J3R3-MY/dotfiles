pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Listening ports you started (dev servers etc.): port, protocol, process,
// pid, command line and working directory straight from /proc. Ports owned
// by apps with a window (browsers, ...) or by other users go into
// "apps" / "system" so the main list stays short.
Singleton {
    id: root

    // [{ port, proto, addr, name, pid, cmd, cwd, kind: "dev"|"app"|"system" }]
    property var ports: []
    readonly property var dev: ports.filter(p => p.kind === "dev")
    readonly property int count: dev.length

    function refresh() { if (!reader.running) reader.running = true; }
    function kill(p) {
        Quickshell.execDetached(["kill", String(p.pid)]);
        root.ports = root.ports.filter(x => x.pid !== p.pid);
        later.restart();
    }
    Timer { id: later; interval: 800; onTriggered: root.refresh() }

    // Prints one TSV line per listening socket, enriched from /proc
    Process {
        id: reader
        command: ["sh", "-c",
            "winpids=\" $(swaymsg -t get_tree 2>/dev/null | grep -o '\"pid\": [0-9]*' | awk '{print $2}' | tr '\\n' ' ') \"; " +
            "ss -ltunpH 2>/dev/null | while read -r proto st rq sq local peer rest; do " +
            "  port=${local##*:}; addr=${local%:*}; " +
            "  pid=$(echo \"$rest\" | sed -n 's/.*pid=\\([0-9]*\\).*/\\1/p'); " +
            "  name=$(echo \"$rest\" | sed -n 's/.*((\"\\([^\"]*\\)\".*/\\1/p'); " +
            "  if [ -z \"$pid\" ]; then kind=system; cmd=; cwd=; " +
            "  else cmd=$(tr '\\0' ' ' < /proc/$pid/cmdline 2>/dev/null | cut -c1-200); cwd=$(readlink /proc/$pid/cwd 2>/dev/null); " +
            "    ppid=$(awk '/^PPid/{print $2}' /proc/$pid/status 2>/dev/null); " +
            "    case \"$winpids\" in *\" $pid \"*|*\" $ppid \"*) kind=app;; *) kind=dev;; esac; fi; " +
            "  printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$port\" \"$proto\" \"$addr\" \"$name\" \"$pid\" \"$cmd\" \"$cwd\" \"$kind\"; " +
            "done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {}, out = [];
                for (const l of text.split("\n")) {
                    const f = l.split("\t");
                    if (f.length < 8) continue;
                    const key = f[0] + "/" + f[1] + "/" + f[4];
                    if (seen[key]) continue;           // same port on v4 + v6
                    seen[key] = true;
                    out.push({ port: parseInt(f[0]), proto: f[1], addr: f[2], name: f[3] || "?", pid: parseInt(f[4]) || 0,
                               cmd: f[5].trim(), cwd: f[6].replace(Quickshell.env("HOME"), "~"), kind: f[7] });
                }
                root.ports = out.sort((a, b) => a.port - b.port);
            }
        }
    }

    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
