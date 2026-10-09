pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default sink/source via native PipeWire bindings. Volume changes from any
// source (your old pamixer keybinds, pavucontrol, ...) show up here, which is
// what lets the OSD react without touching the keybinds.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: [root.sink, root.source].filter(o => !!o)
    }

    readonly property bool ready: !!(sink && sink.audio)
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false
    readonly property int percent: Math.round(volume * 100)
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false
    readonly property string sinkName: sink ? (sink.description || sink.nickname || sink.name) : ""

    function setVolume(v) {
        if (!ready) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1.0, v));
    }
    function toggleMute() { if (ready) sink.audio.muted = !sink.audio.muted; }
    function toggleMic() { if (source && source.audio) source.audio.muted = !source.audio.muted; }
}
