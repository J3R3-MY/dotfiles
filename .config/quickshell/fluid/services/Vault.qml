pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

// Bitwarden through the official `bw` CLI.
//  - the session key lives only in memory and is handed to bw via BW_SESSION
//  - item list is kept without secrets; copying runs `bw get … | wl-copy`
//    so passwords never pass through the shell
//  - copied secrets are dropped from cliphist and cleared after 30 s
//  - locks after 10 min unused and whenever the screen locks
Singleton {
    id: root

    property string status: "unknown"      // unauthenticated | locked | unlocked | missing
    property string email: ""
    property string session: ""
    property var items: []                  // [{ id, name, user, uri, type, totp, fav }]
    property bool busy: false
    property string error: ""
    property string toast: ""

    readonly property bool unlocked: status === "unlocked" && session !== ""

    function refresh() { statusProc.running = true; }

    function unlock(password) {
        if (busy || !password) return;
        busy = true; error = "";
        unlockProc.environment = { "FLUID_BW_PW": password };
        unlockProc.running = true;
    }

    function lock() {
        session = "";
        items = [];
        Quickshell.execDetached(["bw", "lock"]);
        status = status === "unauthenticated" ? status : "locked";
    }

    function login() {
        Quickshell.execDetached(["wezterm", "start", "--", "sh", "-c", "bw login; echo; read -p 'Press Enter to close' _"]);
        loginPoll.restart();
    }

    function sync() { if (unlocked) { busy = true; syncProc.running = true; } }

    // what: "password" | "username" | "totp"
    function copy(item, what) {
        if (!unlocked) return;
        idle.restart();
        Quickshell.execDetached({
            command: ["sh", "-c",
                "v=$(bw get \"$1\" \"$2\") || exit 1; printf '%s' \"$v\" | wl-copy; " +
                // keep secrets out of clipboard history, clear them after 30 s
                "[ \"$1\" = username ] || { sleep 1; cliphist list | head -n1 | cliphist delete; " +
                "(sleep 30; [ \"$(wl-paste -n 2>/dev/null)\" = \"$v\" ] && wl-copy --clear) & }",
                "sh", what, item.id],
            environment: { "BW_SESSION": root.session }
        });
        toast = (what === "totp" ? "Code" : what === "username" ? "Username" : "Password") + " copied" + (what === "username" ? "" : " · clears in 30 s");
        toastTimer.restart();
    }

    function search(q) {
        q = q.trim().toLowerCase();
        const list = q ? items.filter(i => (i.name + " " + i.user + " " + i.uri).toLowerCase().includes(q)) : items;
        return list.slice().sort((a, b) => (b.fav - a.fav) || a.name.localeCompare(b.name));
    }

    Timer { id: toastTimer; interval: 2500; onTriggered: root.toast = "" }
    Timer { id: idle; interval: 10 * 60 * 1000; running: root.unlocked; onTriggered: root.lock() }
    Timer { id: loginPoll; interval: 3000; repeat: true; property int n: 0
        onTriggered: { root.refresh(); if (++n > 60 || root.status !== "unauthenticated") { stop(); n = 0; } } }

    Connections {
        target: Fluid
        function onLockedChanged() { if (Fluid.locked && root.unlocked) root.lock(); }
    }

    Process {
        id: statusProc
        command: ["sh", "-c", "command -v bw >/dev/null || { echo '{\"status\":\"missing\"}'; exit; }; bw status 2>/dev/null | tail -n1"]
        environment: ({ "BW_SESSION": root.session })
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    root.status = j.status === "unlocked" && !root.session ? "locked" : j.status;
                    root.email = j.userEmail || "";
                } catch (e) { root.status = "unknown"; }
            }
        }
    }

    Process {
        id: unlockProc
        command: ["bw", "unlock", "--passwordenv", "FLUID_BW_PW", "--raw"]
        stdout: StdioCollector { id: unlockOut }
        stderr: StdioCollector { id: unlockErr }
        onExited: code => {
            environment = {};
            if (code === 0 && unlockOut.text.trim()) {
                root.session = unlockOut.text.trim();
                root.status = "unlocked";
                listProc.running = true;
            } else {
                root.busy = false;
                root.error = /Invalid master password/i.test(unlockErr.text) ? "Wrong master password" : (unlockErr.text.trim().split("\n").pop() || "Unlock failed");
            }
        }
    }

    Process {
        id: syncProc
        command: ["bw", "sync"]
        environment: ({ "BW_SESSION": root.session })
        onExited: listProc.running = true
    }

    // Item list without any secrets (passwords/notes/cards are dropped here)
    Process {
        id: listProc
        command: ["sh", "-c", "bw list items | jq -c '[.[] | {id, name, type, fav: (.favorite // false), user: (.login.username // \"\"), uri: (.login.uris[0].uri // \"\"), totp: ((.login.totp // \"\") != \"\")}]'"]
        environment: ({ "BW_SESSION": root.session })
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.items = JSON.parse(text); } catch (e) { root.error = "Could not read the vault"; }
                root.busy = false;
                idle.restart();
            }
        }
    }

    Component.onCompleted: refresh()
}
