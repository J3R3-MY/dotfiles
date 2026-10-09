pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

// Wallpaper list + current wallpaper. Applying one hands off to
// scripts/fluid-theme.sh (next to shell.qml), which sets swaybg, runs matugen and
// pushes the new colours to sway/wezterm. The shell picks the colours up by
// watching colors.json (see Theme.qml).
Singleton {
    id: root

    // Every place the wallpapers may live. .config/wallpapers is excluded by
    // .stow-global-ignore, so the repo checkout paths are searched as well.
    readonly property var dirs: {
        const h = Quickshell.env("HOME");
        return [h + "/.config/wallpapers", h + "/dotfiles-fluid/.config/wallpapers",
                h + "/dotfiles/.config/wallpapers", h + "/Pictures/Wallpapers"];
    }
    readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/fluid/wallpaper"
    readonly property string script: Quickshell.shellDir + "/scripts/fluid-theme.sh"

    property var files: []
    property string current: ""
    property string mode: "dark"      // matugen scheme mode: "dark" | "light"
    readonly property bool busy: applier.running

    function rescan() { lister.running = true; }

    function apply(path) {
        if (applier.running) return;
        root.current = path;
        applier.command = [root.script, path, root.mode];
        applier.running = true;
    }

    function setMode(m) {
        if (m === root.mode) return;
        root.mode = m;
        if (root.current) apply(root.current);
    }

    Process {
        id: lister
        running: true
        // Newest first, like the old `ls -t` picker; duplicates (same file
        // name in several dirs) are dropped
        command: ["sh", "-c", "for d; do [ -d \"$d\" ] && find -L \"$d\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) ! -name '._*' -printf '%T@\\t%f\\t%p\\n'; done | sort -rn | awk -F '\\t' '!seen[$2]++ { print $3 }'", "sh"].concat(root.dirs)
        stdout: StdioCollector {
            onStreamFinished: root.files = text.split("\n").filter(l => l.length > 0)
        }
    }

    Connections {
        target: Fluid
        function onThemeChanged() { stateView.reload(); }
    }

    Process {
        id: applier
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) console.warn("fluid-theme:", text.trim())
        }
    }

    FileView {
        id: stateView
        path: root.stateFile
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const p = text().trim();
            if (p.length > 0) root.current = p;
        }
    }

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/fluid/mode"
        printErrors: false
        onLoaded: {
            const m = text().trim();
            if (m === "light" || m === "dark") root.mode = m;
        }
    }
}
