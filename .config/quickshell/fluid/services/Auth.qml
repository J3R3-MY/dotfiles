pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import "../common"

// Password prompts for the system (polkit: pkexec, mounting, NetworkManager,
// installers, ...) shown in the island ("auth" view) instead of the
// polkit-gnome window. Only one agent per session can register: if
// polkit-gnome got there first (sway starts it), it is stopped and the shell
// registers again. Waybar mode starts polkit-gnome again (fluid-launch.sh).
Singleton {
    id: root

    readonly property var agent: loader.item
    readonly property var flow: agent ? agent.flow : null
    readonly property bool active: agent ? agent.isActive : false

    // Who is asking, from the polkit action id (org.freedesktop.NetworkManager.settings.modify → Network Manager)
    readonly property string app: {
        if (!flow) return "";
        const id = flow.actionId || "";
        const names = { policykit: "Administrator access", NetworkManager: "Network Manager", udisks2: "Disks",
                        packagekit: "Software", login1: "Power & sessions", systemd1: "System services",
                        fwupd: "Firmware updates", bluez: "Bluetooth", timedate1: "Date & time",
                        hostname1: "Hostname", locale1: "Language & keyboard", Flatpak: "Flatpak", accounts: "User accounts" };
        const parts = id.split(".").filter(p => ["org", "com", "net", "io", "freedesktop", "gnome", "kde"].indexOf(p) < 0);
        for (const p of parts) if (names[p]) return names[p];
        return parts[0] || id;
    }

    function submit(text) { if (flow && flow.isResponseRequired) flow.submit(text); }
    function cancel() { if (flow && !flow.isCompleted) flow.cancelAuthenticationRequest(); }

    signal failed()

    Loader {
        id: loader
        sourceComponent: PolkitAgent {}
    }
    Connections {
        target: root.agent
        function onAuthenticationRequestStarted() { Fluid.openIsland("auth", ""); }
    }
    Connections {
        target: root.flow
        ignoreUnknownSignals: true
        function onAuthenticationFailed() { root.failed(); }
        function onIsCompletedChanged() { if (root.flow.isCompleted && Fluid.islandView === "auth") Fluid.closeAll(); }
    }
    // Closing the island any other way (Esc, click outside) cancels the request
    Connections {
        target: Fluid
        function onIslandViewChanged() { if (Fluid.islandView !== "auth") root.cancel(); }
    }

    // Registration check: polkit-gnome may hold the session's agent slot
    property int tries: 0
    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: {
            if (root.agent && root.agent.isRegistered) { running = false; return; }
            if (++root.tries > 3) { console.warn("fluid: polkit agent could not register"); running = false; return; }
            Quickshell.execDetached(["pkill", "-x", "polkit-gnome-au"]);   // process names are cut to 15 chars
            loader.active = false;
            reloadLater.start();
        }
    }
    Timer { id: reloadLater; interval: 500; onTriggered: loader.active = true }
}
