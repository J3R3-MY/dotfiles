pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.I3
import Quickshell.Wayland
import "../common"

// Screen time: how long each app had focus. Follows sway's window focus
// events, pauses while idle (2 min) or locked, and keeps one small JSON file
// per day in ~/.local/state/fluid/screentime/YYYY-MM-DD.json:
//   { "apps": { "firefox": 5400, ... }, "hours": [24 x seconds] }
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.local/state/fluid/screentime"

    property string app: ""            // focused app id ("" = desktop)
    property real since: Date.now()
    property string dayKey: key(new Date())
    property var today: ({ apps: {}, hours: new Array(24).fill(0) })
    // Older days, loaded on demand: { "YYYY-MM-DD": { apps, hours } }
    property var history: ({})
    property int revision: 0           // bumps whenever totals change (for bindings)

    readonly property bool counting: !idle.isIdle && !Fluid.locked

    function key(d) {
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
    }

    function total(day) {
        if (!day) return 0;
        return Object.values(day.apps).reduce((a, b) => a + b, 0);
    }

    function dayData(k) { return k === dayKey ? today : (history[k] || null); }

    // Book the time since the last call onto the current app
    function commit() {
        const now = Date.now();
        const secs = (now - since) / 1000;
        since = now;
        if (!counting || secs <= 0 || secs > 600) return;

        const d = new Date();
        const k = key(d);
        if (k !== dayKey) {
            save();
            dayKey = k;
            today = { apps: {}, hours: new Array(24).fill(0) };
        }
        const name = app || "Desktop";
        today.apps[name] = (today.apps[name] || 0) + secs;
        today.hours[d.getHours()] += secs;
        revision++;
    }

    function save() {
        todayFile.setText(JSON.stringify(today));
    }

    function loadHistory() { historyReader.running = true; }

    function prettyName(id) {
        if (id === "Desktop") return id;
        const e = DesktopEntries.heuristicLookup(id);
        if (e) return e.name;
        return id.charAt(0).toUpperCase() + id.slice(1);
    }
    function iconFor(id) {
        if (id === "Desktop") return Quickshell.iconPath("user-desktop", "application-x-executable");
        const e = DesktopEntries.heuristicLookup(id);
        return Quickshell.iconPath(e ? e.icon : id.toLowerCase(), "application-x-executable");
    }

    onCountingChanged: { commit(); }

    IdleMonitor {
        id: idle
        timeout: 120
        respectInhibitors: true   // watching a video keeps counting
    }

    I3IpcListener {
        subscriptions: ["window", "workspace"]
        onIpcEvent: event => {
            try {
                const d = JSON.parse(event.data);
                if (event.type === "window" && d.change === "focus") {
                    root.commit();
                    const c = d.container || {};
                    root.app = c.app_id || (c.window_properties ? c.window_properties.class : "") || "";
                } else if (event.type === "workspace" && d.change === "focus") {
                    const ws = d.current || {};
                    const empty = (ws.nodes || []).length === 0 && (ws.floating_nodes || []).length === 0;
                    if (empty) { root.commit(); root.app = ""; }
                }
            } catch (e) {}
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: { root.commit(); root.save(); }
    }

    FileView {
        id: todayFile
        path: root.dir + "/" + root.dayKey + ".json"
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                const j = JSON.parse(text());
                if (j && j.apps) {
                    if (!j.hours || j.hours.length !== 24) j.hours = new Array(24).fill(0);
                    // merge whatever was counted before the file finished loading
                    for (const [a, s] of Object.entries(root.today.apps)) j.apps[a] = (j.apps[a] || 0) + s;
                    for (let h = 0; h < 24; h++) j.hours[h] += root.today.hours[h];
                    root.today = j;
                    root.revision++;
                }
            } catch (e) {}
        }
    }

    // mkdir once so the first save works
    Process { running: true; command: ["mkdir", "-p", root.dir] }

    Process {
        id: historyReader
        command: ["sh", "-c", "for f in \"$1\"/*.json; do [ -f \"$f\" ] && printf '%s\\t%s\\n' \"$(basename \"$f\" .json)\" \"$(tr -d '\\n' < \"$f\")\"; done", "sh", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                const h = {};
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0) continue;
                    try { h[line.slice(0, tab)] = JSON.parse(line.slice(tab + 1)); } catch (e) {}
                }
                root.history = h;
                root.revision++;
            }
        }
    }

    Component.onDestruction: { commit(); save(); }
}
