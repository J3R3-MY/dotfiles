pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Drives the PipeWire filter-chain EQ from
// .config/pipewire/pipewire.conf.d/fluid-eq.conf. No EasyEffects needed.
// Gains are kept in ~/.local/state/fluid/eq.json and re-applied on start,
// since PipeWire forgets them when it restarts.
Singleton {
    id: root

    readonly property var freqs: ["31", "62", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    readonly property var presets: ({
        "Flat":      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        "Bass":      [6, 5, 4, 2, 0, 0, 0, 0, 0, 0],
        "Treble":    [0, 0, 0, 0, 0, 1, 2, 4, 5, 6],
        "Vocal":     [-2, -2, -1, 1, 3, 4, 3, 1, 0, -1],
        "Pop":       [-1, 1, 3, 4, 2, 0, -1, -1, 0, 1],
        "Rock":      [4, 3, 2, 0, -1, -1, 1, 2, 3, 4],
        "Jazz":      [3, 2, 1, 2, -1, -1, 0, 1, 2, 3],
        "Classical": [4, 3, 2, 1, -1, -1, 0, 2, 3, 4]
    })
    readonly property var presetNames: ["Flat", "Bass", "Treble", "Vocal", "Pop", "Rock", "Jazz", "Classical"]

    property var gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]   // dB, -12 .. 12
    property string preset: "Flat"
    property int nodeId: -1
    readonly property bool available: nodeId >= 0

    function setPreset(name) {
        preset = name;
        gains = presets[name].slice();
        push();
    }

    function setBand(i, db) {
        const g = gains.slice();
        g[i] = Math.max(-12, Math.min(12, Math.round(db)));
        gains = g;
        preset = presetNames.find(n => presets[n].every((v, k) => v === g[k])) || "Custom";
        pushDebounce.restart();
    }

    function push() {
        save();
        if (!available) { find.running = true; return; }
        const params = gains.map((g, i) => `"eq_band_${i + 1}:Gain" ${g.toFixed(1)}`).join(" ");
        Quickshell.execDetached(["pw-cli", "s", String(nodeId), "Props", `{ params = [ ${params} ] }`]);
    }

    function save() {
        stateFile.setText(JSON.stringify({ preset: preset, gains: gains }));
    }

    // Call when the EQ is shown: picks up PipeWire restarts
    function refresh() { find.running = true; }

    Timer { id: pushDebounce; interval: 80; onTriggered: root.push() }

    // Locate the EQ's input node
    Process {
        id: find
        running: true
        command: ["sh", "-c", "pw-dump 2>/dev/null | jq -r '.[] | select(.info.props[\"node.name\"] == \"effect_input.fluid_eq\") | .id' | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const id = parseInt(text.trim());
                const prev = root.nodeId;
                root.nodeId = isNaN(id) ? -1 : id;
                // (re)apply the saved gains whenever the node is new, e.g. after a PipeWire restart
                if (root.available && root.nodeId !== prev) root.push();
            }
        }
    }
    // PipeWire may start after the shell; retry for a while
    Timer {
        interval: 5000
        running: !root.available
        repeat: true
        onTriggered: find.running = true
    }

    FileView {
        id: stateFile
        path: Quickshell.env("HOME") + "/.local/state/fluid/eq.json"
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                const j = JSON.parse(text());
                if (Array.isArray(j.gains) && j.gains.length === 10) root.gains = j.gains;
                if (typeof j.preset === "string") root.preset = j.preset;
            } catch (e) {}
        }
    }
}
