pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default sink/source via native PipeWire bindings. Volume changes from any
// source (your old pamixer keybinds, pavucontrol, ...) show up here, which is
// what lets the OSD react without touching the keybinds.
// Also lists output devices, microphones and the apps playing right now for
// the control center's Sound page.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    // by node type: properties (media.class, ...) only arrive once a node is tracked
    readonly property var outputs: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSink)
    readonly property var inputs: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSource)
    // apps playing (the equalizer's own internal stream left out)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioOutStream && !n.name.startsWith("effect_"))

    PwObjectTracker {
        objects: [root.sink, root.source].concat(root.outputs, root.inputs, root.streams).filter(o => !!o)
    }

    function label(n) { return n ? (n.description || n.nickname || n.name) : ""; }
    function appName(n) { return (n.properties && (n.properties["application.name"] || n.properties["media.name"])) || n.name; }
    function setOutput(n) { Pipewire.preferredDefaultAudioSink = n; }
    function setInput(n) { Pipewire.preferredDefaultAudioSource = n; }
    function setStreamVolume(n, v) { if (n.audio) { n.audio.muted = false; n.audio.volume = Math.max(0, Math.min(1.0, v)); } }

    readonly property bool ready: !!(sink && sink.audio)
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false
    readonly property int percent: Math.round(volume * 100)
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false
    readonly property string sinkName: label(sink)

    function setVolume(v) {
        if (!ready) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1.0, v));
    }
    function toggleMute() { if (ready) sink.audio.muted = !sink.audio.muted; }
    function toggleMic() { if (source && source.audio) source.audio.muted = !source.audio.muted; }
}
