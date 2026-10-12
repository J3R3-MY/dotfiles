import QtQuick
import "."

// Rounded button: hover tint, press bounce, a glyph and/or text.
//   baseColor / hoverColor: background idle / under the pointer
//   textColor: glyph + text; font: the text's font (e.g. a bigger "‹")
// Set `color` directly to override both (e.g. a red "armed" state).
Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property int iconSize: Theme.fontSize + 1
    property color baseColor: Theme.surface
    property color hoverColor: Theme.surfaceHi
    property color textColor: Theme.fg
    property alias font: label.font
    readonly property bool hovered: area.containsMouse
    readonly property bool pressed: area.pressed
    signal clicked()

    implicitHeight: 34
    implicitWidth: Math.max(implicitHeight, row.implicitWidth + 28)
    radius: height / 2
    color: hovered ? hoverColor : baseColor
    scale: pressed ? 0.94 : 1
    Behavior on color { ColorAnimation { duration: Anim.fast } }
    Behavior on scale { Bounce {} }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Glyph { visible: root.icon !== ""; text: root.icon; size: root.iconSize; color: root.textColor; anchors.verticalCenter: parent.verticalCenter }
        Label { id: label; visible: root.text !== ""; text: root.text; color: root.textColor; anchors.verticalCenter: parent.verticalCenter }
    }

    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
