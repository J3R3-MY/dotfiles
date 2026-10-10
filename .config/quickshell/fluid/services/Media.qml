pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    // Only players that actually have a track loaded (an idle spotify_player
    // daemon is an MPRIS player too and may claim to be "playing" nothing)
    readonly property var players: Mpris.players.values.filter(p => p.trackTitle)
    // Prefer whatever is playing, otherwise the first player
    readonly property var player: players.find(p => p.isPlaying) || players[0] || null
    readonly property bool active: !!player
    readonly property bool playing: active && player.isPlaying
    readonly property string title: active ? (player.trackTitle || player.identity) : ""
    readonly property string artist: active ? (player.trackArtist || "") : ""
    readonly property string art: active ? (player.trackArtUrl || "") : ""
    readonly property real length: active && player.lengthSupported ? player.length : 0
    property real position: 0

    // MPRIS position isn't pushed continuously, so tick it while visible+playing
    Timer {
        interval: 1000
        running: root.playing
        repeat: true
        triggeredOnStart: true
        onTriggered: root.position = root.player ? root.player.position : 0
    }

    function toggle() { if (active && player.canTogglePlaying) player.togglePlaying(); }
    function next() { if (active && player.canGoNext) player.next(); }
    function previous() { if (active && player.canGoPrevious) player.previous(); }
    function seek(fraction) {
        if (active && player.canSeek && length > 0) player.position = fraction * length;
    }
}
