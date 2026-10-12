pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Night light (blue light filter): wlsunset makes the screen warmer from
// sunset to sunrise, computed locally from the weather location (no network).
// On/off and strength live in ~/.local/state/fluid/nightlight.json; the
// control center tile and slider change them. Stopping wlsunset restores the
// normal colours.
Singleton {
    id: root

    property bool on: false
    property real strength: 0.5           // 0 = barely warm (5500 K) .. 1 = very warm (2500 K)
    readonly property int temp: Math.round(5500 - strength * 3000)
    readonly property bool available: !isNaN(Weather.lat)

    function toggle() { on = !on; save(); }
    function setStrength(v) { strength = Math.max(0, Math.min(1, v)); save(); restart.restart(); }

    readonly property string file: Quickshell.env("HOME") + "/.local/state/fluid/nightlight.json"
    function save() { store.setText(JSON.stringify({ on: root.on, strength: root.strength })); }
    FileView {
        id: store
        path: root.file
        onLoaded: {
            try { const j = JSON.parse(text()); root.strength = j.strength ?? 0.5; root.on = !!j.on; } catch (e) {}
        }
    }

    // a new strength restarts wlsunset (debounced, the slider moves a lot)
    Timer { id: restart; interval: 400; onTriggered: if (sunset.running) { sunset.running = false; again.start(); } }
    Timer { id: again; interval: 200; onTriggered: sunset.running = Qt.binding(() => root.on && root.available) }

    Process {
        id: sunset
        running: root.on && root.available
        command: ["wlsunset", "-l", String(Weather.lat), "-L", String(Weather.lon), "-t", String(root.temp), "-T", "6500"]
    }
}
