pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Monitor modes through swaymsg. Changes apply immediately and revert after
// 15 s unless kept (like GNOME/macOS); kept settings go to
// ~/.local/state/fluid/sway-outputs.conf, which fluid.conf includes after
// monitors.conf, so they survive a restart without touching the repo.
Singleton {
    id: root

    readonly property string saveFile: Quickshell.env("HOME") + "/.local/state/fluid/sway-outputs.conf"

    // [{ name, make, model, active, width, height, refresh, scale, modes: [{w,h,r}] }]
    property var outputs: []
    property var pendingRevert: null   // { name, cmd } to undo the last change
    property int countdown: 0

    function refresh() { reader.running = true; }

    function modeString(w, h, r) { return w + "x" + h + "@" + (r / 1000).toFixed(3) + "Hz"; }

    function apply(o, w, h, r, scale) {
        const before = "output " + o.name + " mode " + modeString(o.width, o.height, o.refresh) + " scale " + o.scale;
        const after = "output " + o.name + " mode " + modeString(w, h, r) + " scale " + scale;
        pendingRevert = { name: o.name, undo: before, keep: after };
        Quickshell.execDetached(["swaymsg", after]);
        countdown = 15;
        revertTimer.restart();
        refreshLater.restart();
    }

    function keep() {
        if (!pendingRevert) return;
        revertTimer.stop();
        countdown = 0;
        // Replace this output's line in the saved file, keep the others
        const name = pendingRevert.name, line = pendingRevert.keep;
        Quickshell.execDetached(["sh", "-c",
            "f=\"$1\"; mkdir -p \"$(dirname \"$f\")\"; touch \"$f\"; grep -v \"^output $2 \" \"$f\" > \"$f.tmp\"; echo \"$3\" >> \"$f.tmp\"; mv \"$f.tmp\" \"$f\"",
            "sh", root.saveFile, name, line]);
        pendingRevert = null;
    }

    function revert() {
        if (!pendingRevert) return;
        revertTimer.stop();
        countdown = 0;
        Quickshell.execDetached(["swaymsg", pendingRevert.undo]);
        pendingRevert = null;
        refreshLater.restart();
    }

    Timer {
        id: revertTimer
        interval: 1000
        repeat: true
        onTriggered: {
            root.countdown--;
            if (root.countdown <= 0) root.revert();
        }
    }
    Timer { id: refreshLater; interval: 700; onTriggered: root.refresh() }

    Process {
        id: reader
        command: ["swaymsg", "-r", "-t", "get_outputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.outputs = JSON.parse(text).map(o => {
                        const seen = {};
                        const modes = (o.modes || []).filter(m => {
                            const k = m.width + "x" + m.height + "@" + Math.round(m.refresh / 1000);
                            if (seen[k]) return false;
                            seen[k] = true;
                            return true;
                        }).map(m => ({ w: m.width, h: m.height, r: m.refresh }));
                        const cur = o.current_mode || {};
                        return { name: o.name, make: o.make, model: o.model, active: o.active,
                                 width: cur.width || 0, height: cur.height || 0, refresh: cur.refresh || 0,
                                 scale: o.scale || 1, modes: modes };
                    });
                } catch (e) {}
            }
        }
    }
}
