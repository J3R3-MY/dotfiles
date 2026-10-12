pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    // Only players that actually have a track loaded (an idle player may still
    // be on MPRIS and claim to be "playing" nothing)
    readonly property var players: Mpris.players.values.filter(p => p.trackTitle)
    // Prefer whatever is playing, otherwise the first player
    readonly property var player: players.find(p => p.isPlaying) || players[0] || null
    readonly property bool active: !!player
    // After a toggle, show the expected state right away: some players report
    // the change over MPRIS seconds later
    property var _expect: null
    readonly property bool playing: active && (_expect !== null ? _expect : player.isPlaying)
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

    function toggle() {
        if (!active || !player.canTogglePlaying) return;
        // explicit play/pause: togglePlaying() would go by the stale MPRIS state
        _expect = !playing;
        expectTimer.restart();
        if (_expect) player.play(); else player.pause();
    }
    Timer { id: expectTimer; interval: 5000; onTriggered: root._expect = null }
    Connections {
        target: root.player
        // MPRIS reports ~2 s late, so an older press's report can arrive after
        // a newer press: only let go once it matches what we expect
        function onIsPlayingChanged() { if (root.player.isPlaying === root._expect) root._expect = null; }
    }
    function next() { if (active && player.canGoNext) player.next(); }
    function previous() { if (active && player.canGoPrevious) player.previous(); }
    function seek(fraction) {
        if (active && player.canSeek && length > 0) player.position = fraction * length;
    }
}
