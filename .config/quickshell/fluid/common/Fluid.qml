pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.I3

// Global UI state + the IPC surface used by sway keybinds:
//   qs -c fluid ipc call fluid toggle launcher|clipboard|media|calendar|theme|keys
//   qs -c fluid ipc call fluid controlCenter | sound | power | lock
//   qs -c fluid ipc call fluid osd volume|brightness
//   qs -c fluid ipc call fluid reloadTheme
Singleton {
    id: root

    // What the island is showing: "" (resting clock) or one of the views.
    property string islandView: ""
    // Output the island view was opened on, so it only expands on one screen.
    property string islandScreen: ""
    property string ccScreen: ""
    property bool ccOpen: false
    property string ccPage: "main"     // page the control center opens on
    property bool dnd: false
    // Screen recording (scripts/fluid-record.sh tells us over IPC)
    property bool recording: false
    property real recordStart: 0
    function stopRecording() { Quickshell.execDetached([Quickshell.shellDir + "/scripts/fluid-record.sh", "stop"]); }
    // Keep awake: no dimming/locking/sleep on idle (scripts/fluid-idle.sh reads the flag file)
    readonly property string awakeFile: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/fluid-idle/awake"
    property bool awake: false
    function setAwake(on) {
        root.awake = on;
        Quickshell.execDetached(["sh", "-c", on ? "mkdir -p \"${1%/*}\" && touch \"$1\"" : "rm -f \"$1\"", "sh", root.awakeFile]);
    }
    Process {
        running: true
        command: ["test", "-e", root.awakeFile]
        onExited: code => root.awake = code === 0
    }
    property bool powerOpen: false
    property bool netOpen: false
    property string netScreen: ""
    property string netTab: "traffic"     // traffic | health | vpn | ports
    property string powerScreen: ""
    property bool locked: false       // set by the lock screen

    readonly property string focusedScreen: I3.focusedMonitor ? I3.focusedMonitor.name : ""
    readonly property var views: ["launcher", "clipboard", "media", "calendar", "theme", "keys", "vault"]

    signal osdRequested(string kind)
    signal lockRequested()
    // Sent by fluid-theme.sh after matugen ran, in case the file watch missed it
    signal themeChanged()

    function openIsland(view, screenName) {
        root.ccOpen = false;
        root.powerOpen = false;
        root.netOpen = false;
        root.islandScreen = screenName || root.focusedScreen;
        root.islandView = view;
    }

    function toggleIsland(view, screenName) {
        if (root.islandView === view) closeAll();
        else openIsland(view, screenName);
    }

    function toggleNet(tab, screenName) {
        const same = root.netOpen && root.netTab === tab;
        root.islandView = "";
        root.ccOpen = false;
        root.powerOpen = false;
        root.netScreen = screenName || root.focusedScreen;
        root.netTab = tab;
        root.netOpen = !same;
    }

    function togglePower(screenName) {
        root.islandView = "";
        root.ccOpen = false;
        root.netOpen = false;
        root.powerScreen = screenName || root.focusedScreen;
        root.powerOpen = !root.powerOpen;
    }

    function toggleControlCenter(screenName, page) {
        root.ccPage = page || "main";
        root.islandView = "";
        root.powerOpen = false;
        root.netOpen = false;
        root.ccScreen = screenName || root.focusedScreen;
        root.ccOpen = !root.ccOpen;
    }

    function closeAll() {
        root.islandView = "";
        root.ccOpen = false;
        root.powerOpen = false;
        root.netOpen = false;
    }

    IpcHandler {
        target: "fluid"

        function toggle(view: string): void {
            if (root.views.indexOf(view) === -1) {
                console.warn("fluid: unknown view", view);
                return;
            }
            root.toggleIsland(view, "");
        }
        function controlCenter(): void { root.toggleControlCenter(""); }
        function sound(): void { root.toggleControlCenter("", "sound"); }
        function power(): void { root.togglePower(""); }
        function network(tab: string): void { root.toggleNet(tab || "traffic", ""); }
        function lock(): void { root.lockRequested(); }
        function close(): void { root.closeAll(); }
        function osd(kind: string): void { root.osdRequested(kind); }
        function dnd(): void { root.dnd = !root.dnd; }
        function reloadTheme(): void { root.themeChanged(); }
        function recording(on: bool): void { root.recording = on; if (on) root.recordStart = Date.now(); }
    }
}
