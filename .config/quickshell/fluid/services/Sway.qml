pragma Singleton
import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Io

// Sway state through Quickshell's native i3/sway IPC (no swaymsg polling).
Singleton {
    id: root

    // Current binding mode ("" when in the default mode), like waybar's sway/mode
    property string mode: ""
    // Workspace name -> app ids of its windows (app_id, or X11 class), for the bar icons
    property var apps: ({})
    // Active keyboard layout as a short code ("DE", "US") and how many are configured
    property string layout: ""
    property int layoutCount: 0
    function nextLayout() { I3.dispatch("input type:keyboard xkb_switch_layout next"); }

    I3IpcListener {
        subscriptions: ["input"]
        onIpcEvent: if (!inputs.running) inputs.running = true
    }
    Process {
        id: inputs
        running: true
        command: ["swaymsg", "-t", "get_inputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                let kb = null;
                try { kb = JSON.parse(text).find(i => i.type === "keyboard" && i.xkb_active_layout_name); } catch (e) {}
                if (!kb) return;
                const codes = { "German": "DE", "English (US)": "US", "English (UK)": "UK", "French": "FR" };
                const n = kb.xkb_active_layout_name;
                root.layout = codes[n] || n.slice(0, 2).toUpperCase();
                root.layoutCount = (kb.xkb_layout_names || []).length;
            }
        }
    }

    function workspacesFor(screenName) {
        return I3.workspaces.values
            .filter(w => w.monitor && w.monitor.name === screenName)
            // named workspaces (number -1, e.g. "m" for Spotify) after the numbered ones
            .sort((a, b) => (a.number < 0 ? 1e6 : a.number) - (b.number < 0 ? 1e6 : b.number));
    }

    function focusWorkspace(ws) {
        if (ws.number > 0) I3.dispatch("workspace number " + ws.number);
        else I3.dispatch("workspace \"" + ws.name + "\"");
    }


    // Window list from the tree, refreshed on window/workspace events
    I3IpcListener {
        subscriptions: ["window", "workspace"]
        onIpcEvent: treeDebounce.restart()
    }
    Timer { id: treeDebounce; interval: 150; onTriggered: tree.running = true }
    Process {
        id: tree
        running: true
        command: ["swaymsg", "-t", "get_tree"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                const walk = (n, ws) => {
                    if (n.type === "workspace") { ws = n.name; out[ws] = []; }
                    if (ws && n.pid) {
                        const id = (n.app_id || (n.window_properties || {}).class || "").toLowerCase();
                        if (id && !out[ws].includes(id)) out[ws].push(id);
                    }
                    for (const c of (n.nodes || []).concat(n.floating_nodes || [])) walk(c, ws);
                };
                try { walk(JSON.parse(text), ""); root.apps = out; } catch (e) {}
            }
        }
    }

    I3IpcListener {
        subscriptions: ["mode"]
        onIpcEvent: event => {
            try {
                const change = JSON.parse(event.data).change;
                root.mode = change === "default" ? "" : change;
            } catch (e) {}
        }
    }
}
