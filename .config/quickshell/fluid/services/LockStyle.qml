pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Which lock screen design is active (lock/Lock<Name>.qml), saved in
// ~/.local/state/fluid/lock.json. Picked in the lock style view.
Singleton {
    id: root

    readonly property var designs: [
        { id: "classic", name: "Classic", file: "LockClassic.qml", about: "Big clock, password on any key" },
        { id: "minimal", name: "Minimal", file: "LockMinimal.qml", about: "Small clock in the corner, no blur" },
        { id: "info", name: "Info", file: "LockInfo.qml", about: "Weather, music and system at a glance" },
        { id: "split", name: "Split", file: "LockSplit.qml", about: "Stacked clock on a solid panel" }
    ]
    property string design: "classic"
    readonly property string file: (designs.find(d => d.id === design) || designs[0]).file

    function set(id) {
        design = id;
        store.setText(JSON.stringify({ design: id }));
    }

    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.local/state/fluid/lock.json"
        printErrors: false
        atomicWrites: true
        onLoaded: { try { const j = JSON.parse(text()); if (j.design) root.design = j.design; } catch (e) {} }
    }
}
