import QtQuick
import "."

// Thick rounded slider (control center / OSD). `value` is 0..1.
// Emits `moved(v)` while dragging; the owner writes it back to the service.
Item {
    id: root

    property real value: 0
    property string icon: ""
    property color fillColor: Theme.accent
    property bool interactive: true
    signal moved(real v)
    signal iconClicked()

    implicitHeight: 40
    implicitWidth: 260

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceHi
        clip: true

        Rectangle {
            height: parent.height
            radius: parent.radius
            width: Math.max(height, parent.width * Math.max(0, Math.min(1, root.value)))
            color: root.fillColor
            Behavior on width {
                enabled: !drag.pressed
                NumberAnimation { duration: Anim.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized }
            }
        }
    }

    Glyph {
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: Theme.onPill
        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            enabled: root.interactive
            onClicked: root.iconClicked()
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        anchors.leftMargin: 40
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        function update(mx) {
            const v = Math.max(0, Math.min(1, (mx + 40) / root.width));
            root.moved(v);
        }
        onPressed: m => update(m.x)
        onPositionChanged: m => { if (pressed) update(m.x); }
        onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
