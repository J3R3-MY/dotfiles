import QtQuick
import "../common"

// Labelled slider for the theme tweaks. Centred ranges (e.g. -1..1) fill from
// the middle so "0 = default" is visible at a glance. Double-click resets.
Item {
    id: root

    property string label: ""
    property real from: -1
    property real to: 1
    property real value: 0
    property real defaultValue: 0
    property real step: 0.05
    property string suffix: ""
    property int decimals: 2
    property string valueText: ""     // overrides the number shown on the right
    // Hue mode: the track shows the colour wheel around `baseHue` (0..1),
    // so the knob sits on the colour you'll actually get
    property bool hueTrack: false
    property real baseHue: 0
    signal moved(real v)

    implicitHeight: 44
    implicitWidth: 260

    readonly property real frac: (value - from) / (to - from)
    readonly property real zeroFrac: Math.max(0, Math.min(1, (defaultValue - from) / (to - from)))

    function set(v) {
        v = Math.max(from, Math.min(to, Math.round(v / step) * step));
        if (Math.abs(v - value) > 1e-6) root.moved(v);
    }

    Label {
        id: title
        text: root.label
        dim: true
        size: "sm"
    }
    Label {
        anchors.right: parent.right
        text: root.valueText || (root.value > 0 && root.from < 0 ? "+" : "") + root.value.toFixed(root.decimals) + root.suffix
        size: "sm"
    }

    Item {
        id: trackArea
        anchors.bottom: parent.bottom
        width: parent.width
        height: 20

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 8
            radius: 4
            color: Theme.surfaceHi
            clip: true

            Row {
                visible: root.hueTrack
                anchors.fill: parent
                Repeater {
                    model: root.hueTrack ? 36 : 0
                    Rectangle {
                        required property int index
                        width: track.width / 36 + 0.5
                        height: track.height
                        color: Qt.hsla(((root.baseHue + (index / 35 - 0.5)) % 1 + 1) % 1, 0.65, 0.6, 1)
                    }
                }
            }

            // Fill from the default value to the current value
            Rectangle {
                visible: !root.hueTrack
                height: parent.height
                radius: parent.radius
                x: parent.width * Math.min(root.frac, root.zeroFrac)
                width: parent.width * Math.abs(root.frac - root.zeroFrac)
                color: Theme.clock
            }
        }

        Rectangle {
            id: knob
            width: 18; height: 18; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: root.frac * (trackArea.width - width)
            color: Theme.fg
            border.width: 3
            border.color: Theme.clock
            scale: drag.pressed ? 1.2 : 1
            Behavior on scale { NumberAnimation { duration: Anim.fast; easing.type: Easing.OutBack } }
            Behavior on x {
                enabled: !drag.pressed
                NumberAnimation { duration: Anim.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized }
            }
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            function at(mx) { root.set(root.from + Math.max(0, Math.min(1, (mx - 6) / trackArea.width)) * (root.to - root.from)); }
            onPressed: m => at(m.x)
            onPositionChanged: m => { if (pressed) at(m.x); }
            onDoubleClicked: root.moved(root.defaultValue)
            onWheel: w => root.set(root.value + (w.angleDelta.y > 0 ? root.step : -root.step))
        }
    }
}
