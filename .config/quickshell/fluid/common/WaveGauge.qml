import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets
import "."

// Round gauge filled with "liquid" up to the value: two sine waves (the back
// one fainter, slower) slide sideways inside a clipped disc. The wave paths
// are built once per size; only their x position animates.
Item {
    id: root

    property real value: 0          // 0..1
    property string text: ""
    property color color: Theme.clock
    property real size: 96

    implicitWidth: size
    implicitHeight: size

    property real shown: Math.max(0, Math.min(1, value))
    Behavior on shown { NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } }

    readonly property real amp: size * 0.055
    // the surface bobs a little so the liquid never looks like a loop
    property real bob: 0
    SequentialAnimation on bob {
        running: root.visible
        loops: Animation.Infinite
        NumberAnimation { to: 1; duration: 2300; easing.type: Easing.InOutSine }
        NumberAnimation { to: -1; duration: 2300; easing.type: Easing.InOutSine }
    }
    // a sine wave `period` px long; the path is one period longer than the
    // gauge so sliding it by one period loops seamlessly with no edge showing
    function wave(period, phase) {
        const pts = [], w = size + period + 12;
        for (let x = 0; x <= w; x += 3)
            pts.push(Qt.point(x, amp + amp * Math.sin(x / period * 2 * Math.PI + phase)));
        pts.push(Qt.point(w, size + amp * 2), Qt.point(0, size + amp * 2));
        return pts;
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.surfaceHi

        Repeater {
            // back wave: shorter, fainter, drifting the other way; different
            // lengths and speeds keep the two from lining up into a pattern
            model: [{ period: 0.7, phase: 1.6, alpha: 0.4, ms: 3100, dir: 1, bob: -1.5 },
                    { period: 1.0, phase: 0, alpha: 0.9, ms: 2600, dir: -1, bob: 2 }]
            Shape {
                id: waveShape
                required property var modelData
                readonly property real period: root.size * modelData.period
                width: root.size + period + 12
                height: root.size + root.amp * 2
                y: (1 - root.shown) * root.size - root.amp + root.bob * modelData.bob
                layer.enabled: true
                layer.samples: 4
                ShapePath {
                    strokeColor: "transparent"
                    fillColor: Qt.alpha(root.color, modelData.alpha)
                    PathPolyline { path: root.wave(waveShape.period, modelData.phase) }
                }
                NumberAnimation on x {
                    from: modelData.dir < 0 ? 0 : -waveShape.period
                    to: modelData.dir < 0 ? -waveShape.period : 0
                    duration: modelData.ms
                    loops: Animation.Infinite
                    running: root.visible
                }
            }
        }

        // thin rim so it reads as a round vessel
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(Theme.fg, 0.12)
        }
    }

    Label {
        anchors.centerIn: parent
        text: root.text
        style: Text.Outline
        styleColor: Qt.alpha(Theme.bg, 0.6)
        font.pixelSize: root.size * 0.2; font.weight: Font.Bold
    }
}
