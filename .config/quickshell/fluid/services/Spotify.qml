pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Spotify through spotify_player (Arch package `spotify-player`) running as a
// daemon (started by fluid.conf). Playback itself shows up in the normal media
// view through MPRIS; this service adds search, library and Connect devices
// via spotify_player's CLI, which talks to the running daemon.
// One-time setup: `spotify_player authenticate` (needs Spotify Premium).
// Each CLI call starts a new client (= a login prompt) when no instance is
// running, so nothing calls the CLI until credentials are cached and the
// daemon is up.
Singleton {
    id: root

    property string state: "unknown"        // missing | login | offline | ready
    readonly property bool ready: state === "ready"
    property bool _loadWhenReady: false
    property var results: ({ tracks: [], albums: [], artists: [], playlists: [] })
    property var playlists: []
    property var liked: []
    property var devices: []
    property bool loading: false

    function id(x) { return String(x || "").split(":").pop(); }
    function artists(t) { return (t.artists || []).map(a => a.name).join(", "); }

    function check() { if (!checker.running) checker.running = true; }
    // Used by the Spotify view: check, then load the library once it's reachable
    function open() { _loadWhenReady = true; check(); }

    function search(q) {
        if (!ready) return;
        if (!q.trim()) { results = { tracks: [], albums: [], artists: [], playlists: [] }; return; }
        loading = true;
        searchProc.command = ["spotify_player", "search", q];
        searchProc.running = true;
    }
    function loadLibrary() {
        if (ready && !libProc.running) libProc.running = true;
    }

    function playTrack(t) { run(["playback", "start", "track", "--id", id(t.id)]); }
    function playContext(kind, item) { run(["playback", "start", "context", kind, "--id", id(item.id)]); }
    function playLiked() { run(["playback", "start", "liked"]); }
    function connect(d) { run(["connect", "--id", d.id]); later.restart(); }
    function authenticate() {
        Quickshell.execDetached(["wezterm", "start", "--", "sh", "-c",
            "spotify_player authenticate && (pkill -x spotify_player; setsid -f spotify_player -d); echo; read -p 'Done. Press Enter' _"]);
    }

    function run(args) { if (ready) Quickshell.execDetached(["spotify_player"].concat(args)); }

    Timer { id: later; interval: 1500; onTriggered: root.loadLibrary() }

    Process {
        id: checker
        command: ["sh", "-c", "command -v spotify_player >/dev/null || { echo missing; exit; }; " +
                              "c=\"$HOME/.cache/spotify-player\"; ls \"$c\"/*_token.json >/dev/null 2>&1 && [ -f \"$c/credentials.json\" ] || { echo login; exit; }; " +
                              "pgrep -x spotify_player >/dev/null || { setsid -f spotify_player -d >/dev/null 2>&1; sleep 3; }; " +
                              "pgrep -x spotify_player >/dev/null && timeout 5 spotify_player get key devices >/dev/null 2>&1 && echo ready || echo offline"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.state = text.trim() || "offline";
                if (root.ready && root._loadWhenReady) root.loadLibrary();
                root._loadWhenReady = false;
            }
        }
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
