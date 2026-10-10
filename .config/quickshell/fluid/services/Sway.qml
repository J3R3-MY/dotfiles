pragma Singleton
import QtQuick
import Quickshell
import Quickshell.I3

// Sway state through Quickshell's native i3/sway IPC (no swaymsg polling).
Singleton {
    id: root

    // Current binding mode ("" when in the default mode), like waybar's sway/mode
    property string mode: ""

    function workspacesFor(screenName) {
        return I3.workspaces.values
            .filter(w => w.monitor && w.monitor.name === screenName)
            .sort((a, b) => a.number - b.number);
    }

    function focusWorkspace(ws) {
        if (ws.number > 0) I3.dispatch("workspace number " + ws.number);
        else I3.dispatch("workspace \"" + ws.name + "\"");
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
