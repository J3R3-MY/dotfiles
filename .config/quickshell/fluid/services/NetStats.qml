pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live throughput from /proc/net/dev (bytes/s, smoothed), a 30-minute
// history for the chart, link details, and a rough per-app split from
// `ss -tinp` socket counters. VPN/container interfaces are skipped so tunnel
// traffic isn't counted twice.
Singleton {
    id: root

    property real down: 0           // bytes/s, smoothed
    property real up: 0
    property real totalDown: 0      // bytes since boot over counted interfaces
    property real totalUp: 0
    property var history: []        // [{ t, down, up }] one sample per 2 s, 30 min
    property var details: ({})      // ssid, signal, bitrate, freq, ip, gateway, dns, mac, mtu, iface
    property var apps: []           // [{ name, down, up }] bytes/s, top 6
    property bool detailed: false   // panel open -> also poll details + apps

    readonly property var skip: /^(lo|tun|tap|wg|tailscale|docker|br-|veth|virbr|vnet|zt|nordlynx|proton|mullvad)/

    property var _prev: null
    property var _prevApps: ({})

    function fmt(bps) {
        const u = ["B", "K", "M", "G"];
        let i = 0;
        while (bps >= 1024 && i < u.length - 1) { bps /= 1024; i++; }
        return (bps < 10 && i > 0 ? bps.toFixed(1) : Math.round(bps)) + u[i];
    }

    FileView {
        id: dev
        path: "/proc/net/dev"
        onLoaded: {
            let rx = 0, tx = 0;
            for (const line of text().split("\n").slice(2)) {
                const m = line.trim().match(/^([^:]+):\s*(.*)$/);
                if (!m || root.skip.test(m[1])) continue;
                const f = m[2].split(/\s+/).map(Number);
                rx += f[0]; tx += f[8];
            }
            const now = Date.now();
            if (root._prev) {
                const dt = (now - root._prev.t) / 1000;
                if (dt > 0) {
                    const d = Math.max(0, (rx - root._prev.rx) / dt), u = Math.max(0, (tx - root._prev.tx) / dt);
                    // exponential moving average keeps the number from jittering
                    root.down = root.down * 0.4 + d * 0.6;
                    root.up = root.up * 0.4 + u * 0.6;
                    const h = root.history.concat([{ t: now, down: d, up: u }]);
                    root.history = h.length > 900 ? h.slice(h.length - 900) : h;
                }
            }
            root._prev = { t: now, rx: rx, tx: tx };
            root.totalDown = rx;
            root.totalUp = tx;
        }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: dev.reload() }

    // ---- Link details (only while the panel is open) -----------------------
    Process {
        id: detailProc
        command: ["sh", "-c",
            "dev=$(ip route show default | awk '{for(i=1;i<=NF;i++) if($i==\"dev\"){print $(i+1); exit}}'); " +
            "gw=$(ip route show default | awk '{print $3; exit}'); " +
            "echo \"iface=$dev\"; echo \"gateway=$gw\"; " +
            "echo \"ip=$(ip -4 -o addr show dev \"$dev\" 2>/dev/null | awk '{print $4; exit}')\"; " +
            "echo \"mac=$(cat /sys/class/net/$dev/address 2>/dev/null)\"; echo \"mtu=$(cat /sys/class/net/$dev/mtu 2>/dev/null)\"; " +
            "echo \"dns=$(awk '/^nameserver/{print $2}' /etc/resolv.conf | paste -sd ' ')\"; " +
            "iw dev \"$dev\" link 2>/dev/null | sed -n 's/^\\s*SSID: \\(.*\\)/ssid=\\1/p; s/^\\s*signal: \\(.*\\)/signal=\\1/p; s/^\\s*tx bitrate: \\([0-9.]* [A-Za-z/]*\\).*/bitrate=\\1/p; s/^\\s*freq: \\([0-9.]*\\).*/freq=\\1/p'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const d = {};
                for (const l of text.split("\n")) { const i = l.indexOf("="); if (i > 0) d[l.slice(0, i)] = l.slice(i + 1); }
                root.details = d;
            }
        }
    }

    // Per-app: sum socket byte counters per process, diff against last poll
    Process {
        id: appProc
        command: ["sh", "-c", "ss -tinpH 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const now = Date.now(), cur = {};
                let name = "";
                for (const l of text.split("\n")) {
                    const p = l.match(/users:\(\("([^"]+)"/);
                    if (p) { name = p[1]; continue; }
                    if (!name) continue;
                    const rcv = l.match(/bytes_received:(\d+)/), snd = l.match(/bytes_acked:(\d+)/);
                    if (rcv || snd) {
                        cur[name] = cur[name] || { rx: 0, tx: 0 };
                        cur[name].rx += rcv ? Number(rcv[1]) : 0;
                        cur[name].tx += snd ? Number(snd[1]) : 0;
                        name = "";
                    }
                }
                const prev = root._prevApps, dt = prev._t ? (now - prev._t) / 1000 : 0, out = [];
                if (dt > 0) for (const [n, v] of Object.entries(cur)) {
                    const pv = prev[n] || v;
                    const d = Math.max(0, (v.rx - pv.rx) / dt), u = Math.max(0, (v.tx - pv.tx) / dt);
                    if (d + u > 0) out.push({ name: n, down: d, up: u });
                }
                cur._t = now;
                root._prevApps = cur;
                root.apps = out.sort((a, b) => (b.down + b.up) - (a.down + a.up)).slice(0, 6);
            }
        }
    }
    Timer {
        interval: 3000; running: root.detailed; repeat: true; triggeredOnStart: true
        onTriggered: { detailProc.running = true; appProc.running = true; }
    }
}
