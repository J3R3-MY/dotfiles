pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.I3

// Global UI state + the IPC surface used by sway keybinds:
//   qs -c fluid ipc call fluid toggle launcher|clipboard|media|calendar|theme
//   qs -c fluid ipc call fluid controlCenter
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
    property bool dnd: false

    readonly property string focusedScreen: I3.focusedMonitor ? I3.focusedMonitor.name : ""
    readonly property var views: ["launcher", "clipboard", "media", "calendar", "theme"]

    signal osdRequested(string kind)
    // Sent by fluid-theme.sh after matugen ran, in case the file watch missed it
    signal themeChanged()

    function openIsland(view, screenName) {
        root.ccOpen = false;
        root.islandScreen = screenName || root.focusedScreen;
        root.islandView = view;
    }

    function toggleIsland(view, screenName) {
        if (root.islandView === view) closeAll();
        else openIsland(view, screenName);
    }

    function toggleControlCenter(screenName) {
        root.islandView = "";
        root.ccScreen = screenName || root.focusedScreen;
        root.ccOpen = !root.ccOpen;
    }

    function closeAll() {
        root.islandView = "";
        root.ccOpen = false;
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
        function close(): void { root.closeAll(); }
        function osd(kind: string): void { root.osdRequested(kind); }
        function dnd(): void { root.dnd = !root.dnd; }
        function reloadTheme(): void { root.themeChanged(); }
    }
}
