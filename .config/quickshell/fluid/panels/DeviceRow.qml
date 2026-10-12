import QtQuick
import "../common"

// One selectable device in the control center (Sound page): dot + name,
// filled when it's the current one.
Rectangle {
    id: dr
    property string title
    property bool selected: false
    signal clicked()
    width: parent ? parent.width : 0
    height: 40; radius: 14
    color: dr.selected ? Theme.surfaceHi : (drArea.containsMouse ? Theme.surface : "transparent")
    Rectangle {
        id: dot
        x: 14; anchors.verticalCenter: parent.verticalCenter
        width: 10; height: 10; radius: 5
        color: dr.selected ? Theme.audio : "transparent"
        border.width: 2; border.color: dr.selected ? Theme.audio : Theme.fgDim
    }
    Label {
        anchors.left: dot.right; anchors.leftMargin: 12
        anchors.right: parent.right; anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        text: dr.title
    }
    MouseArea { id: drArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dr.clicked() }
}
