pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Listening ports: who owns each one, what it's for and who can reach it.
// Your own processes come with pid, command line and working directory from
// /proc; system sockets (no pid without root) are named by their systemd
// service, read from the socket's cgroup (`ss -e`). Ports owned by apps with a
// window (browsers, ...) or by services go into "apps" / "system" so the main
// list stays short.
Singleton {
    id: root

    // [{ port, proto, addr, scope, name, purpose, desc, pid, cmd, cwd, kind: "dev"|"app"|"system" }]
    property var ports: []
    readonly property var dev: ports.filter(p => p.kind === "dev")
    readonly property int count: dev.length

    // What well-known ports are for
    readonly property var purposes: ({
        22: "SSH", 53: "DNS", 67: "DHCP", 68: "DHCP", 123: "time sync", 546: "DHCPv6 (getting an address)",
        631: "printing", 1716: "KDE Connect", 5353: "mDNS (finds printers, TVs, ...)",
        5355: "LLMNR (local name lookup)", 41641: "Tailscale VPN traffic", 57621: "Spotify Connect"
    })

    // Who can connect: 2 = all networks, 1 = one interface, 0 = this computer
    function reach(addr) {
        const a = addr.replace(/[\[\]]/g, "");
        if (a.startsWith("127.") || a.startsWith("::1") || a.endsWith("%lo")) return 0;
        if (a === "*" || a === "0.0.0.0" || a === "::") return 2;
        return 1;
    }
    function scopeText(p) {
        if (p.reach === 0) return "this computer only";
        if (p.reach === 2) return "listens on all networks";
        const i = p.addr.indexOf("%");
        return i >= 0 ? "on " + p.addr.slice(i + 1) : "on " + p.addr;
    }

    function refresh() { if (!reader.running) reader.running = true; }
    function kill(p) {
        Quickshell.execDetached(["kill", String(p.pid)]);
        root.ports = root.ports.filter(x => x.pid !== p.pid);
        later.restart();
    }
    Timer { id: later; interval: 800; onTriggered: root.refresh() }

    // One TSV line per listening socket, enriched from /proc, then
    // "U <unit> <description>" for every service that owns one
    Process {
        id: reader
        command: ["sh", "-c",
            "winpids=\" $(swaymsg -t get_tree 2>/dev/null | grep -o '\"pid\": [0-9]*' | awk '{print $2}' | tr '\\n' ' ') \"; " +
            "out=$(ss -ltunpeH 2>/dev/null); " +
            "printf '%s\\n' \"$out\" | while read -r proto st rq sq local peer rest; do " +
            "  [ -n \"$local\" ] || continue; port=${local##*:}; addr=${local%:*}; " +
            "  pid=$(echo \"$rest\" | sed -n 's/.*pid=\\([0-9]*\\).*/\\1/p'); " +
            "  name=$(echo \"$rest\" | sed -n 's/.*((\"\\([^\"]*\\)\".*/\\1/p'); " +
            "  unit=$(echo \"$rest\" | sed -n 's/.*cgroup:[^ ]*\\/\\([^ /]*\\.service\\).*/\\1/p'); " +
            "  if [ -z \"$pid\" ]; then kind=system; cmd=; cwd=; " +
            "  else cmd=$(tr '\\0' ' ' < /proc/$pid/cmdline 2>/dev/null | cut -c1-200); cwd=$(readlink /proc/$pid/cwd 2>/dev/null); " +
            "    ppid=$(awk '/^PPid/{print $2}' /proc/$pid/status 2>/dev/null); " +
            "    case \"$winpids\" in *\" $pid \"*|*\" $ppid \"*) kind=app;; *) kind=dev;; esac; fi; " +
            "  printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$port\" \"$proto\" \"$addr\" \"$name\" \"$pid\" \"$cmd\" \"$cwd\" \"$kind\" \"$unit\"; " +
            "done; " +
            "printf '%s\\n' \"$out\" | sed -n 's/.*cgroup:[^ ]*\\/\\([^ /]*\\.service\\).*/\\1/p' | sort -u " +
            "  | xargs -r systemctl show -p Id -p Description 2>/dev/null " +
            "  | awk '/^Id=/ { id = substr($0, 4) } /^Description=/ { print \"U\\t\" id \"\\t\" substr($0, 13) }'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const desc = {}, socks = [];
                for (const l of text.split("\n")) {
                    const f = l.split("\t");
                    if (f[0] === "U" && f.length >= 3) desc[f[1]] = f[2];
                    else if (f.length >= 9) socks.push(f);
                }
                // One entry per port + owner: v4/v6 and tcp/udp twins merge,
                // the widest reach wins
                const byKey = {}, out = [];
                for (const f of socks) {
                    const port = parseInt(f[0]), pid = parseInt(f[4]) || 0, unit = f[8];
                    const key = port + "/" + (pid || unit || f[3]);
                    const r = root.reach(f[2]);
                    const e = byKey[key];
                    if (e) {
                        if (e.proto.indexOf(f[1]) < 0) e.proto += "+" + f[1];
                        if (r > e.reach) { e.reach = r; e.addr = f[2]; }
                        continue;
                    }
                    byKey[key] = {
                        port: port, proto: f[1], addr: f[2], reach: r, pid: pid,
                        name: f[3] || unit.replace(/\.service$/, "") || "?",
                        purpose: root.purposes[port] || "", desc: desc[unit] || "",
                        cmd: f[5].trim(), cwd: f[6].replace(Quickshell.env("HOME"), "~"), kind: f[7]
                    };
                    out.push(byKey[key]);
                }
                for (const p of out) p.scope = root.scopeText(p);
                root.ports = out.sort((a, b) => a.port - b.port);
            }
        }
    }

    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
