pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values
        .filter(a => !a.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    // Simple ranking: prefix match > word-prefix match > substring > fuzzy
    function search(query) {
        const q = query.trim().toLowerCase();
        if (q.length === 0) return root.all;
        const scored = [];
        for (const a of root.all) {
            const name = a.name.toLowerCase();
            const extra = ((a.genericName || "") + " " + (a.comment || "") + " " + (a.id || "")).toLowerCase();
            let s = -1;
            if (name.startsWith(q)) s = 100;
            else if (name.split(/[\s\-_]/).some(w => w.startsWith(q))) s = 80;
            else if (name.includes(q)) s = 60;
            else if (extra.includes(q)) s = 40;
            else if (fuzzy(name, q)) s = 20;
            if (s >= 0) scored.push({ app: a, score: s });
        }
        scored.sort((x, y) => (y.score - x.score) || x.app.name.localeCompare(y.app.name));
        return scored.map(x => x.app);
    }

    function fuzzy(text, q) {
        let i = 0;
        for (const c of text) if (c === q[i]) i++;
        return i === q.length;
    }

    function launch(app) {
        // Through swaymsg so the window opens on the workspace it was launched
        // from, same reason the old $menu piped into `swaymsg exec`.
        const cmd = app.command.map(a => "'" + a.replace(/'/g, "'\\''") + "'").join(" ");
        Quickshell.execDetached(["swaymsg", "exec", "--", app.runInTerminal ? "wezterm start -- " + cmd : cmd]);
    }
}
