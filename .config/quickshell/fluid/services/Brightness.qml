pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Laptop backlight from sysfs. sysfs doesn't emit inotify events, so it is
// polled; that is how the OSD notices your existing brightnessctl keybinds.
Singleton {
    id: root

    property string device: ""
    property int max: 0
    property int current: 0
    readonly property bool available: device.length > 0 && max > 0
    readonly property real value: available ? current / max : 0
    readonly property int percent: Math.round(value * 100)
    // fluid-idle.sh is dimming the screen (keeps the OSD quiet)
    property bool idleDimmed: false

    function set(v) {
        if (!available) return;
        const pct = Math.max(1, Math.min(100, Math.round(v * 100)));
        Quickshell.execDetached(["brightnessctl", "-q", "-d", root.device, "set", pct + "%"]);
        root.current = Math.round(pct / 100 * root.max);
    }

    Process {
        running: true
        command: ["sh", "-c", "ls /sys/class/backlight | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: root.device = text.trim()
        }
    }

    FileView {
        id: maxFile
        path: root.device ? "/sys/class/backlight/" + root.device + "/max_brightness" : ""
        printErrors: false
        onLoaded: root.max = parseInt(text()) || 0
    }

    FileView {
        id: curFile
        path: root.device ? "/sys/class/backlight/" + root.device + "/brightness" : ""
        printErrors: false
        onLoaded: root.current = parseInt(text()) || 0
    }

    FileView {
        id: dimFile
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/fluid-idle/dim"
        printErrors: false
        onLoaded: root.idleDimmed = true
        onLoadFailed: root.idleDimmed = false
    }

    Timer {
        interval: 250
        running: root.available
        repeat: true
        onTriggered: { dimFile.reload(); curFile.reload(); }
    }
}
