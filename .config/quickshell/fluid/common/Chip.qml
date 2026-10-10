import QtQuick
import "."

// Rounded text button / tab / filter chip. `on` fills it with the accent.
Rectangle {
    id: root

    property string text
    property bool on: false
    property bool outlined: false      // thin border while off (style/preset chips)
    property int size: Theme.fontSize - 3
    signal clicked()

    height: size + 15
    radius: height / 2
    width: label.implicitWidth + height - 4
    color: on ? Theme.clock : (area.containsMouse ? Theme.surfaceHi : (outlined ? "transparent" : Theme.surface))
    border.width: outlined && !on ? 1 : 0
    border.color: Theme.border
    scale: area.pressed ? 0.95 : 1
    Behavior on color { ColorAnimation { duration: Anim.fast } }
    Behavior on scale { NumberAnimation { duration: Anim.fast; easing.type: Easing.OutBack } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.on ? Theme.onPill : Theme.fg
        font.family: Theme.font
        font.pixelSize: root.size
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
