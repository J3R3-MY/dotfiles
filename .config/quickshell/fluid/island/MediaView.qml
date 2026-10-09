import QtQuick
import Quickshell.Widgets
import "../common"
import "../services"

// Now-playing card with album art, seekable progress and controls.
Item {
    id: root

    function fmt(s) {
        s = Math.max(0, Math.floor(s));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    Keys.onEscapePressed: Fluid.closeAll()
    Keys.onSpacePressed: Media.toggle()
    Component.onCompleted: forceActiveFocus()

    Text {
        anchors.centerIn: parent
        visible: !Media.active
        text: "Nothing playing"
        color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize
    }

    Row {
        anchors.fill: parent
        spacing: 16
        visible: Media.active

        ClippingRectangle {
            width: parent.height; height: parent.height
            radius: 14
            color: Theme.surfaceHi
            Glyph { anchors.centerIn: parent; text: Icons.music; size: 40; color: Theme.fgDim; visible: art.status !== Image.Ready }
            Image {
                id: art
                anchors.fill: parent
                source: Media.art
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Anim.normal } }
            }
        }

        Column {
            width: parent.width - parent.height - 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                width: parent.width; elide: Text.ElideRight
                text: Media.title
                color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize + 2; font.weight: Font.DemiBold
            }
            Text {
                width: parent.width; elide: Text.ElideRight
                text: Media.artist
                color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
            }

            // Progress
            Item {
                width: parent.width
                height: 18
                visible: Media.length > 0
                Rectangle {
                    id: track
                    width: parent.width; height: 6; radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.surfaceHi
                    Rectangle {
                        height: parent.height; radius: 3
                        width: parent.width * Math.min(1, Media.position / Math.max(1, Media.length))
                        color: Theme.clock
                        Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: m => Media.seek(m.x / width)
                }
            }
            Row {
                width: parent.width
                visible: Media.length > 0
                Text { width: parent.width / 2; text: root.fmt(Media.position); color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
                Text { width: parent.width / 2; horizontalAlignment: Text.AlignRight; text: root.fmt(Media.length); color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
            }

            Row {
                spacing: 14
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: [
                        { icon: Icons.prev, act: () => Media.previous(), big: false },
                        { icon: Media.playing ? Icons.pause : Icons.play, act: () => Media.toggle(), big: true },
                        { icon: Icons.next, act: () => Media.next(), big: false }
                    ]
                    Rectangle {
                        required property var modelData
                        width: modelData.big ? 44 : 36; height: width; radius: width / 2
                        color: modelData.big ? Theme.clock : (ctl.containsMouse ? Theme.surfaceHi : "transparent")
                        scale: ctl.pressed ? 0.88 : 1
                        Behavior on scale { NumberAnimation { duration: Anim.fast; easing.type: Easing.OutBack } }
                        Glyph { anchors.centerIn: parent; text: parent.modelData.icon; color: parent.modelData.big ? Theme.onPill : Theme.fg }
                        MouseArea { id: ctl; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData.act() }
                    }
                }
            }
        }
    }
}
