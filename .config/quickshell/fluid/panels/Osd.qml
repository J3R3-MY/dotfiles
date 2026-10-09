import QtQuick
import "../common"
import "../services"

// macOS-style volume/brightness indicator, bottom centre of the focused output.
// It watches the values themselves, so it appears for *any* change: your old
// pamixer/brightnessctl keybinds, pavucontrol, scrolling on the bar, ...
Item {
    id: root

    property string kind: "volume"
    property bool shown: false
    // Ignore the initial values reported at startup
    property bool armed: false

    width: 320
    height: 64

    function show(k) {
        if (!armed || Fluid.ccOpen) return;
        if (k === "brightness" && !Brightness.available) return;
        kind = k;
        shown = true;
        hideTimer.restart();
    }

    Timer { interval: 2000; running: true; onTriggered: root.armed = true }
    Timer { id: hideTimer; interval: 1400; onTriggered: root.shown = false }

    Connections {
        target: Audio
        function onVolumeChanged() { root.show("volume"); }
        function onMutedChanged() { root.show("volume"); }
    }
    Connections {
        target: Brightness
        function onCurrentChanged() { root.show("brightness"); }
    }
    Connections {
        target: Fluid
        function onOsdRequested(k) { root.armed = true; root.show(k); }
    }

    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.9
    visible: opacity > 0
    transform: Translate { y: root.shown ? 0 : 24; Behavior on y { NumberAnimation { duration: Anim.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } } }
    Behavior on opacity { NumberAnimation { duration: Anim.normal } }
    Behavior on scale { NumberAnimation { duration: Anim.normal; easing.type: Easing.OutBack } }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.bg
        border.width: 2
        border.color: Theme.border
    }

    FSlider {
        anchors.fill: parent
        anchors.margins: 12
        interactive: false
        value: root.kind === "volume" ? (Audio.muted ? 0 : Audio.volume) : Brightness.value
        icon: root.kind === "volume" ? Icons.volume(Audio.percent, Audio.muted) : Icons.sun
        fillColor: root.kind === "volume" ? Theme.audio : Theme.backlight
    }
}
