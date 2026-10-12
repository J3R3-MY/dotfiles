import QtQuick
import "."

// Quick-settings tile: icon + title + subtitle, filled when on.
Rectangle {
    id: root

    property bool on: false
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool hasMore: false     // shows a chevron that opens a detail page
    signal clicked()
    signal more()

    implicitHeight: 58
    implicitWidth: 150
    radius: 16
    color: on ? Theme.accent : Qt.alpha(Theme.surfaceHi, 0.6)
    Behavior on color { ColorAnimation { duration: Anim.normal } }
    scale: area.pressed ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: Anim.fast; easing.type: Easing.OutBack } }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 14
        spacing: 12

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            size: 20
            color: root.on ? Theme.onPill : Theme.fg
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: root.width - 60 - (root.hasMore ? 30 : 0)
            Text {
                width: parent.width
                text: root.title
                elide: Text.ElideRight
                color: root.on ? Theme.onPill : Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                font.weight: Font.DemiBold
            }
            Text {
                width: parent.width
                visible: text.length > 0
                text: root.subtitle
                elide: Text.ElideRight
                color: root.on ? Theme.onPill : Theme.fgDim
                opacity: 0.85
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 3
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.rightMargin: root.hasMore ? 36 : 0
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Rectangle {
        visible: root.hasMore
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 36
        radius: root.radius
        color: moreArea.containsMouse ? Qt.rgba(0, 0, 0, 0.12) : "transparent"
        Text {
            anchors.centerIn: parent
            text: "›"
            font.pixelSize: 22
            color: root.on ? Theme.onPill : Theme.fg
        }
        MouseArea {
            id: moreArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.more()
        }
    }
}
