import QtQuick
import "."

// Segmented switch with a sliding highlight.
// options: [{ value, label }]; emits picked(value).
Rectangle {
    id: root

    property var options: []
    property var current
    signal picked(var value)

    readonly property int sel: Math.max(0, options.findIndex(o => o.value === current))
    readonly property real segW: (width - 8) / Math.max(1, options.length)

    implicitHeight: 36
    radius: 14
    color: Theme.surface

    Rectangle {
        x: 4 + root.sel * root.segW
        y: 4
        width: root.segW
        height: parent.height - 8
        radius: parent.radius - 3
        color: Theme.clock
        Behavior on x { NumberAnimation { duration: Anim.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.spring } }
    }

    Row {
        anchors.fill: parent
        anchors.margins: 4
        Repeater {
            model: root.options
            Item {
                required property var modelData
                required property int index
                width: root.segW
                height: parent.height
                Label {
                    anchors.centerIn: parent
                    text: parent.modelData.label
                    color: root.sel === parent.index ? Theme.onPill : Theme.fg
                    size: "sm"
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(parent.modelData.value)
                }
            }
        }
    }
}
