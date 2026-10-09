pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// cliphist history. Needs the two `wl-paste --watch cliphist store` lines
// in the sway autostart (added by fluid.conf).
Singleton {
    id: root

    property var entries: []   // [{ id, text, image }]

    function refresh() { lister.running = true; }

    function copy(entry) {
        Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", entry.id]);
    }

    function remove(entry) {
        Quickshell.execDetached(["sh", "-c", "printf '%s\\t%s\\n' \"$1\" \"$2\" | cliphist delete", "sh", entry.id, entry.raw]);
        root.entries = root.entries.filter(e => e.id !== entry.id);
    }

    function wipe() {
        Quickshell.execDetached(["cliphist", "wipe"]);
        root.entries = [];
    }

    Process {
        id: lister
        command: ["sh", "-c", "cliphist list | head -n 200"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0) continue;
                    const raw = line.slice(tab + 1);
                    out.push({ id: line.slice(0, tab), raw: raw, text: raw, image: raw.startsWith("[[ binary data") });
                }
                root.entries = out;
            }
        }
    }
}
