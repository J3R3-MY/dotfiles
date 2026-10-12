import QtQuick
import "."

// A bar module in the old waybar style: coloured rounded box, dark text.
// On hover it grows to reveal `detail` next to the main label, which is the
// "fluid" part; width changes are animated with the emphasized curve.
Item {
    id: root

    property color color: Theme.clock
    property color textColor: Theme.onPill
    property string icon: ""
    property string label: ""
    property string detail: ""
    property bool alert: false
    readonly property bool hovered: mouse.containsMouse

    signal clicked(var mouse)
    signal scrolled(int delta)

    implicitHeight: Theme.pillHeight
    implicitWidth: row.implicitWidth + 16

    Behavior on implicitWidth {
        NumberAnimation { duration: Anim.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized }
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: Theme.pillRadius
        color: root.alert ? Theme.urgent : root.color
        scale: mouse.pressed ? 0.94 : 1.0
        Behavior on scale { NumberAnimation { duration: Anim.fast; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: Anim.normal } }

        // Critical-battery blink, same idea as the waybar keyframes
        SequentialAnimation on opacity {
            running: root.alert
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation { to: 0.55; duration: 500 }
            NumberAnimation { to: 1.0; duration: 500 }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Label {
            visible: root.label.length > 0
            text: root.label
            color: root.alert ? Theme.fg : root.textColor
            size: "lg"
            anchors.verticalCenter: parent.verticalCenter
        }

        // Hover detail slides open between label and icon
        Item {
            id: detailBox
            anchors.verticalCenter: parent.verticalCenter
            height: detailText.implicitHeight
            width: root.hovered && root.detail.length > 0 ? detailText.implicitWidth : 0
            clip: true
            visible: width > 0
            Behavior on width {
                NumberAnimation { duration: Anim.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized }
            }
            Label {
                id: detailText
                text: root.detail
                color: root.alert ? Theme.fg : root.textColor
                opacity: root.hovered ? 0.85 : 0
                Behavior on opacity { NumberAnimation { duration: Anim.normal } }
            }
        }

        Glyph {
            visible: root.icon.length > 0
            text: root.icon
            color: root.alert ? Theme.fg : root.textColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => root.clicked(m)
        onWheel: w => root.scrolled(w.angleDelta.y > 0 ? 1 : -1)
    }
}
