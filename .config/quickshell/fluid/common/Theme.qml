pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Colours for the whole shell.
//
// The defaults are the exact hex values from the old waybar style.css, so with
// no wallpaper picked yet the bar looks the way it always did. Picking a
// wallpaper runs matugen, which writes ~/.local/state/fluid/colors.json; this
// file watches it and every colour animates to the new value.
Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/fluid"
    property var palette: ({})

    function pick(key, fallback) {
        const v = root.palette[key];
        return (typeof v === "string" && v.length > 0) ? v : fallback;
    }

    // Base
    property color bg: pick("bg", "#0e0c0c")
    property color surface: pick("surface", "#161313")
    property color surfaceHi: pick("surfaceHi", "#3d3535")
    property color border: pick("border", "#3d3535")
    property color fg: pick("fg", "#ffffff")
    property color fgDim: pick("fgDim", "#a7a097")
    property color onPill: pick("onPill", "#0e0c0c")
    property color accent: pick("accent", "#7c8671")
    property color urgent: pick("urgent", "#6b5d5c")
    property color mode: pick("mode", "#605b54")

    // Per-module pill colours (same roles as the waybar modules)
    property color clock: pick("clock", "#c4bca4")
    property color battery: pick("battery", "#a79088")
    property color cpu: pick("cpu", "#7c8671")
    property color memory: pick("memory", "#f5ebcd")
    property color backlight: pick("backlight", "#a7a097")
    property color network: pick("network", "#9ba78d")
    property color audio: pick("audio", "#d0b4aa")
    property color bluetooth: pick("bluetooth", "#9ba78d")

    readonly property int colorMs: 650
    Behavior on bg { ColorAnimation { duration: root.colorMs } }
    Behavior on surface { ColorAnimation { duration: root.colorMs } }
    Behavior on surfaceHi { ColorAnimation { duration: root.colorMs } }
    Behavior on border { ColorAnimation { duration: root.colorMs } }
    Behavior on fg { ColorAnimation { duration: root.colorMs } }
    Behavior on fgDim { ColorAnimation { duration: root.colorMs } }
    Behavior on onPill { ColorAnimation { duration: root.colorMs } }
    Behavior on accent { ColorAnimation { duration: root.colorMs } }
    Behavior on urgent { ColorAnimation { duration: root.colorMs } }
    Behavior on clock { ColorAnimation { duration: root.colorMs } }
    Behavior on battery { ColorAnimation { duration: root.colorMs } }
    Behavior on cpu { ColorAnimation { duration: root.colorMs } }
    Behavior on memory { ColorAnimation { duration: root.colorMs } }
    Behavior on backlight { ColorAnimation { duration: root.colorMs } }
    Behavior on network { ColorAnimation { duration: root.colorMs } }
    Behavior on audio { ColorAnimation { duration: root.colorMs } }
    Behavior on bluetooth { ColorAnimation { duration: root.colorMs } }

    // Typography and metrics (waybar: Roboto 17px, 37px bar, 5px radius)
    readonly property string font: "Roboto"
    readonly property int fontSize: 15
    readonly property int barHeight: 37
    readonly property int pillHeight: 29
    readonly property int pillRadius: 8
    readonly property int panelRadius: 18

    Connections {
        target: Fluid
        function onThemeChanged() { colorsFile.reload(); }
    }

    FileView {
        id: colorsFile
        path: root.stateDir + "/colors.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.palette = JSON.parse(text());
            } catch (e) {
                console.warn("fluid: ignoring unreadable colors.json:", e);
            }
        }
    }
}
