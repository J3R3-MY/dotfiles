pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// File and folder search for the launcher, with fd over your home folder.
// Runs only while you type (150 ms after the last key, a newer query stops
// the older search). Several words: the longest one is searched in names, the
// others must appear somewhere in the path ("hypr config" finds ~/.config/hypr).
// Dotfiles are included; caches, trash, VCS and build folders are skipped,
// and so is anything your .gitignore files exclude.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    property string query: ""
    // [{ path, name, dir, isDir }]
    property var results: []

    function search(q) {
        root.query = q.trim();
        if (root.query.length < 2) { root.results = []; finder.running = false; return; }
        debounce.restart();
    }

    function open(f) { Quickshell.execDetached(["xdg-open", f.path]); }
    function reveal(f) { Quickshell.execDetached(["thunar", f.path]); }
    function copyPath(f) { Quickshell.execDetached(["wl-copy", "--", f.path]); }

    Timer {
        id: debounce
        interval: 150
        onTriggered: {
            const terms = root.query.toLowerCase().split(/\s+/).sort((a, b) => b.length - a.length);
            finder.terms = terms;
            finder.running = false;
            finder.command = ["fd", "--hidden", "--ignore-case", "--fixed-strings", "--max-results", "300",
                "--exclude", ".git", "--exclude", "node_modules", "--exclude", ".cache", "--exclude", "__pycache__",
                "--exclude", ".venv", "--exclude", "target", "--exclude", ".local/share/Trash", "--exclude", ".npm",
                "--exclude", ".cargo", "--exclude", ".rustup", "--exclude", ".mozilla", "--exclude", ".var",
                "--exclude", ".local/share/Steam", "--exclude", ".local/state",
                "--", terms[0], root.home];
            finder.running = true;
        }
    }

    Process {
        id: finder
        property var terms: []
        stdout: StdioCollector {
            onStreamFinished: {
                const t = finder.terms, out = [];
                for (let p of text.split("\n")) {
                    if (!p) continue;
                    const isDir = p.endsWith("/");
                    if (isDir) p = p.slice(0, -1);
                    const lower = p.toLowerCase();
                    if (!t.every(w => lower.includes(w))) continue;
                    const name = p.slice(p.lastIndexOf("/") + 1);
                    const rel = p.slice(root.home.length + 1);
                    // name starts with the query > name contains it, then shallow and short paths first
                    const score = (name.toLowerCase().startsWith(t[0]) ? 0 : 1) * 1000 + rel.split("/").length * 40 + rel.length;
                    out.push({ path: p, name: name, dir: "~/" + rel.slice(0, Math.max(0, rel.length - name.length - 1)), isDir: isDir, score: score });
                }
                root.results = out.sort((a, b) => a.score - b.score).slice(0, 40);
            }
        }
    }
}
