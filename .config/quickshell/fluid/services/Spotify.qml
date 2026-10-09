pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Spotify through spotify_player (Arch package `spotify-player`) running as a
// daemon (started by fluid.conf). Playback itself shows up in the normal media
// view through MPRIS; this service adds search, library and Connect devices
// via spotify_player's CLI, which talks to the running daemon.
// One-time setup: `spotify_player authenticate` (needs Spotify Premium).
Singleton {
    id: root

    property string state: "unknown"        // missing | offline | ready
    property var results: ({ tracks: [], albums: [], artists: [], playlists: [] })
    property var playlists: []
    property var liked: []
    property var devices: []
    property bool loading: false

    function id(x) { return String(x || "").split(":").pop(); }
    function artists(t) { return (t.artists || []).map(a => a.name).join(", "); }
    function secs(d) { return d ? (d.secs !== undefined ? d.secs : Math.round(d / 1000)) : 0; }

    function check() { if (!checker.running) checker.running = true; }

    function search(q) {
        if (!q.trim()) { results = { tracks: [], albums: [], artists: [], playlists: [] }; return; }
        loading = true;
        searchProc.command = ["spotify_player", "search", q];
        searchProc.running = true;
    }
    function loadLibrary() {
        if (!libProc.running) libProc.running = true;
    }

    function playTrack(t) { run(["playback", "start", "track", "--id", id(t.id)]); }
    function playContext(kind, item) { run(["playback", "start", "context", kind, "--id", id(item.id)]); }
    function playLiked() { run(["playback", "start", "liked"]); }
    function connect(d) { run(["connect", "--id", d.id]); later.restart(); }
    function authenticate() {
        Quickshell.execDetached(["wezterm", "start", "--", "sh", "-c",
            "spotify_player authenticate && (pkill -x spotify_player; setsid -f spotify_player -d); echo; read -p 'Done. Press Enter' _"]);
    }

    function run(args) { Quickshell.execDetached(["spotify_player"].concat(args)); }

    Timer { id: later; interval: 1500; onTriggered: root.loadLibrary() }

    Process {
        id: checker
        command: ["sh", "-c", "command -v spotify_player >/dev/null || { echo missing; exit; }; " +
                              "timeout 5 spotify_player get key devices >/dev/null 2>&1 && echo ready || echo offline"]
        stdout: StdioCollector { onStreamFinished: root.state = text.trim() || "offline" }
    }

    Process {
        id: searchProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                try {
                    const j = JSON.parse(text);
                    root.results = { tracks: j.tracks || [], albums: j.albums || [], artists: j.artists || [], playlists: j.playlists || [] };
                } catch (e) {}
            }
        }
    }

    // Playlists, liked songs and devices in one go, separated by marker lines
    Process {
        id: libProc
        command: ["sh", "-c", "echo '#playlists'; spotify_player get key user-playlists; echo; echo '#liked'; spotify_player get key user-liked-tracks; echo; echo '#devices'; spotify_player get key devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                let key = "";
                for (const line of text.split("\n")) {
                    if (line.startsWith("#")) { key = line.slice(1); continue; }
                    if (!line.trim()) continue;
                    try {
                        const j = JSON.parse(line);
                        if (key === "playlists") root.playlists = j;
                        else if (key === "liked") root.liked = j;
                        else if (key === "devices") root.devices = j.map(d => Array.isArray(d)
                            ? { name: d[0], id: d[1], active: false }
                            : { name: d.name, id: d.id, active: !!(d.is_active || d.is_integrated) });
                    } catch (e) {}
                }
            }
        }
    }

    Component.onCompleted: check()
}
