pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// NetworkManager via nmcli. `nmcli monitor` streams changes so we only
// re-query when something actually happens.
Singleton {
    id: root

    property string type: "none"      // "wifi" | "ethernet" | "none"
    property string name: ""          // SSID or connection name
    property string device: ""
    property string ip: ""
    property int signal: 0
    property bool wifiEnabled: true
    property var networks: []         // [{ ssid, signal, secure, active }]
    readonly property bool connected: type !== "none"

    function refresh() { if (!status.running) status.running = true; }
    function scan() { if (!scanner.running) scanner.running = true; }

    function setWifi(on) {
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]);
        root.wifiEnabled = on;
    }

    function connect(ssid) {
        // Known networks reconnect directly; for new secured ones nmcli would
        // need a password, so fall back to nmtui in a floating terminal
        // (the sway config already floats windows titled nmtui-connect).
        connector.command = ["sh", "-c",
            "nmcli -w 15 connection up id \"$1\" || nmcli -w 15 device wifi connect \"$1\" " +
            "|| wezterm start --class nmtui-connect -- nmtui-connect \"$1\"", "sh", ssid];
        connector.running = true;
    }

    Process {
        id: status
        command: ["sh", "-c",
            "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status | " +
            // Always emit exactly one line here so the fields below stay at fixed indexes
            "awk -F: '$3==\"connected\" && ($2==\"wifi\"||$2==\"ethernet\") {print; f=1; exit} END {if (!f) print \"\"}'; " +
            "echo; nmcli radio wifi; " +
            "nmcli -t -f IN-USE,SIGNAL dev wifi list --rescan no 2>/dev/null | awk -F: '$1==\"*\"{print $2; exit}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                const f = (lines[0] || "").split(":");
                if (f.length >= 4) {
                    root.device = f[0];
                    root.type = f[1];
                    root.name = f.slice(3).join(":");
                    ipProc.running = true;
                } else {
                    root.type = "none";
                    root.name = "";
                    root.ip = "";
                }
                root.wifiEnabled = (lines[2] || "").trim() === "enabled";
                root.signal = parseInt(lines[3]) || 0;
            }
        }
    }

    Process {
        id: ipProc
        command: ["sh", "-c", "ip -4 -o addr show dev \"$1\" | awk '{print $4; exit}'", "sh", root.device]
        stdout: StdioCollector { onStreamFinished: root.ip = text.trim() }
    }

    Process {
        id: scanner
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "dev", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const out = [];
                for (const line of text.split("\n")) {
                    const p = line.split(":");
                    if (p.length < 4) continue;
                    const ssid = p.slice(3).join(":").replace(/\\:/g, ":");
                    if (!ssid || seen[ssid]) continue;
                    seen[ssid] = true;
                    out.push({ ssid: ssid, signal: parseInt(p[1]) || 0, secure: p[2].length > 0 && p[2] !== "--", active: p[0] === "*" });
                }
                out.sort((a, b) => (b.active - a.active) || (b.signal - a.signal));
                root.networks = out;
            }
        }
    }

    Process {
        id: connector
        onExited: root.refresh()
    }

    // Event stream: any line from nmcli monitor means "something changed"
    Process {
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: debounce.restart() }
    }

    Timer { id: debounce; interval: 400; onTriggered: root.refresh() }
    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
