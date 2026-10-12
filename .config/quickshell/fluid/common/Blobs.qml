import QtQuick
import QtQuick.Shapes
import "."

// Soft colour blobs drifting slowly behind a panel's content (radial
// gradients, no blur pass). Each blob wanders on its own slow figure-eight;
// one shared clock drives them and only runs while the panel is visible.
Item {
    id: root

    property var colors: [Theme.clock, Theme.network, Theme.audio]
    property real strength: 0.22    // centre opacity of each blob
    property real t: 0
    NumberAnimation on t { from: 0; to: 2 * Math.PI; duration: 60000; loops: Animation.Infinite; running: root.visible }

    Repeater {
        model: root.colors
        Shape {
            id: blob
            required property color modelData
            required property int index
            readonly property real r: Math.max(root.width, root.height) * (0.42 - index * 0.06)
            readonly property real p: index * 2.1
            width: r * 2; height: r * 2
            x: root.width * (0.5 + 0.38 * Math.sin(root.t * (index + 1) + p)) - r
            y: root.height * (0.5 + 0.34 * Math.sin(root.t * (index + 2) + p * 1.7)) - r
            ShapePath {
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: blob.r; centerY: blob.r; centerRadius: blob.r
                    focalX: blob.r; focalY: blob.r
                    GradientStop { position: 0; color: Qt.alpha(blob.modelData, root.strength) }
                    GradientStop { position: 0.55; color: Qt.alpha(blob.modelData, root.strength * 0.35) }
                    GradientStop { position: 1; color: Qt.alpha(blob.modelData, 0) }
                }
                PathAngleArc { centerX: blob.r; centerY: blob.r; radiusX: blob.r; radiusY: blob.r; startAngle: 0; sweepAngle: 360 }
            }
        }
    }
}
