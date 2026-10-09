pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// VPN status and switching across whatever is installed:
//  - NetworkManager profiles of type vpn / wireguard (OpenVPN, WireGuard, ...)
//  - Tailscale (incl. exit nodes)
//  - Mullvad, if its CLI exists
// Each backend only shows up if it has something to offer.
Singleton {
    id: root

    // [{ backend, id, name, active }]
    property var profiles: []
    property bool tailscale: false
    property bool tailscaleUp: false
    property string tailscaleExit: ""
    property var exitNodes: []               // [{ id, name, online }]
    property bool mullvad: false
    property bool mullvadUp: false
    property string mullvadWhere: ""
    property bool busy: false

    readonly property bool available: profiles.length > 0 || tailscale || mullvad
    readonly property bool connected: profiles.some(p => p.active) || tailscaleUp && tailscaleExit !== "" || mullvadUp
    readonly property string label: {
        const p = profiles.find(x => x.active);
        if (p) return p.name;
        if (mullvadUp) return "Mullvad" + (mullvadWhere ? " · " + mullvadWhere : "");
        if (tailscaleUp && tailscaleExit) return "Tailscale · " + tailscaleExit;
        return "";
    }

    function refresh() { if (!reader.running) reader.running = true; }

    function run(cmd) {
        busy = true;
        runner.command = cmd;
        runner.running = true;
    }

    function toggleProfile(p) { run(["nmcli", "connection", p.active ? "down" : "up", "uuid", p.id]); }
    function setTailscale(on) { run(["tailscale", on ? "up" : "down"]); }
    function setExitNode(id) { run(["tailscale", "set", "--exit-node=" + id]); }
    function setMullvad(on) { run(["mullvad", on ? "connect" : "disconnect"]); }

    Process {
        id: reader
        command: ["sh", "-c",
            "nmcli -t -f UUID,TYPE,NAME,ACTIVE connection show 2>/dev/null | awk -F: '$2==\"vpn\"||$2==\"wireguard\"{print \"nm:\"$0}'; " +
            "if command -v tailscale >/dev/null; then echo 'ts:present'; tailscale status --json 2>/dev/null | tr -d '\\n' | sed 's/^/tsjson:/'; echo; fi; " +
            "if command -v mullvad >/dev/null; then echo \"mv:$(mullvad status 2>/dev/null | head -n2 | tr '\\n' ' ')\"; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const profiles = [];
                let ts = false, tsUp = false, tsExit = "", nodes = [], mv = false, mvUp = false, mvWhere = "";
                for (const l of text.split("\n")) {
                    if (l.startsWith("nm:")) {
                        const f = l.slice(3).split(":");
                        profiles.push({ backend: "nm", id: f[0], type: f[1], name: f.slice(2, -1).join(":"), active: f[f.length - 1] === "yes" });
                    } else if (l === "ts:present") {
                        ts = true;
                    } else if (l.startsWith("tsjson:")) {
                        try {
                            const j = JSON.parse(l.slice(7));
                            tsUp = j.BackendState === "Running";
                            for (const p of Object.values(j.Peer || {})) {
                                if (p.ExitNodeOption) nodes.push({ id: p.DNSName.split(".")[0], name: p.HostName, online: p.Online });
                                if (p.ExitNode) tsExit = p.HostName;
                            }
                        } catch (e) {}
                    } else if (l.startsWith("mv:")) {
                        mv = true;
                        mvUp = /Connected/.test(l) && !/Disconnected/.test(l);
                        const m = l.match(/Relay:\s*(\S+)/) || l.match(/in\s+([^,]+)/);
                        mvWhere = m ? m[1] : "";
                    }
                }
                root.profiles = profiles;
                root.tailscale = ts; root.tailscaleUp = tsUp; root.tailscaleExit = tsExit; root.exitNodes = nodes;
                root.mullvad = mv; root.mullvadUp = mvUp; root.mullvadWhere = mvWhere;
            }
        }
    }

    Process {
        id: runner
        stderr: StdioCollector { onStreamFinished: if (text.trim()) console.warn("fluid vpn:", text.trim()) }
        onExited: { root.busy = false; root.refresh(); }
    }

    Timer { interval: 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
