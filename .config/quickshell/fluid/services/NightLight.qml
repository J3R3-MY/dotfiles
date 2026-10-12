pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Night light (blue light filter): while on, wlsunset keeps the screen warm
// (day and night temperature 1 K apart = no schedule, warm right away; the
// location is only there because wlsunset wants one).
// On/off and strength live in ~/.local/state/fluid/nightlight.json; the
// control center tile and slider change them. Stopping wlsunset restores the
// normal colours.
Singleton {
    id: root

    property bool on: false
    // five strengths, 0 = barely warm .. 4 = very warm
    readonly property var temps: [4800, 4200, 3700, 3200, 2700]
    property int level: 2
    readonly property int temp: temps[level]
    property bool available: true         // false = wlsunset not installed

    function toggle() { on = !on; save(); }
    // wlsunset can't change temperature while running: stop it, and start the
    // new one only once the old one has exited (it holds the gamma control;
    // starting too early fails and leaves the screen at normal colours)
    function setLevel(i) {
        if (i === level) return;
        level = Math.max(0, Math.min(4, i));
        save();
        if (sunset.running) restarting = true;
    }
    property bool restarting: false
    Timer { interval: 2000; running: root.restarting; onTriggered: root.restarting = false }   // safety net

    readonly property string file: Quickshell.env("HOME") + "/.local/state/fluid/nightlight.json"
    function save() { store.setText(JSON.stringify({ on: root.on, level: root.level })); }
    FileView {
        id: store
        path: root.file
        onLoaded: {
            try {
                const j = JSON.parse(text());
                root.level = j.level ?? Math.round((j.strength ?? 0.5) * 4);   // older files had a 0..1 strength
                root.on = !!j.on;
            } catch (e) {}
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v wlsunset"]
        onExited: code => root.available = code === 0
    }

    Process {
        id: sunset
        running: root.on && root.available && !root.restarting
        // --pdeathsig: wlsunset exits with the shell (a leftover one would
        // keep the gamma control and block the next start)
        command: ["setpriv", "--pdeathsig", "TERM", "wlsunset", "-l", "0", "-L", "0", "-t", String(root.temp), "-T", String(root.temp + 1)]
        onExited: root.restarting = false
    }
}
