import QtQuick
import Quickshell
import Quickshell.Widgets
import "../common"
import "../services"
import "../lock"

// Lock screen picker: live previews of every design (rendered at full size
// and scaled down). Click to choose, "Try it" locks right away.
Item {
    id: root

    Keys.onEscapePressed: Fluid.closeAll()
    Component.onCompleted: forceActiveFocus()

    // Stand-in for the real lock state so previews show the password field
    QtObject {
        id: fake
        property bool authMode: true
        property string password: "hunter2"
        property string status: ""
        property bool busy: false
        property string user: Quickshell.env("USER") || "you"
        signal shake()
    }

    Row {
        id: header
        width: parent.width
        spacing: 10
        Glyph { text: Icons.lock; color: Theme.clock; size: 18; anchors.verticalCenter: parent.verticalCenter }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Lock screen"
            color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.DemiBold
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: header.verticalCenter
        height: 30; radius: 15
        width: tryText.implicitWidth + 26
        color: tryArea.containsMouse ? Theme.clock : Theme.surface
        Text { id: tryText; anchors.centerIn: parent; text: "Try it  " + Icons.lock; color: tryArea.containsMouse ? Theme.onPill : Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
        MouseArea { id: tryArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Fluid.closeAll(); Fluid.lockRequested(); } }
    }

    Grid {
        id: grid
        anchors.top: header.bottom
        anchors.topMargin: 14
        columns: 2
        spacing: 14
        readonly property real cardW: (root.width - 14) / 2
        readonly property real cardH: cardW * 9 / 16 + 40

        Repeater {
            model: LockStyle.designs
            Item {
                id: card
                required property var modelData
                readonly property bool chosen: LockStyle.design === modelData.id
                width: grid.cardW; height: grid.cardH

                ClippingRectangle {
                    id: frame
                    width: parent.width; height: parent.width * 9 / 16
                    radius: 14
                    color: Theme.surfaceHi
                    border.width: card.chosen ? 3 : 1
                    border.color: card.chosen ? Theme.clock : Theme.border
                    scale: area.containsMouse ? 1.02 : 1
                    Behavior on scale { NumberAnimation { duration: Anim.fast; easing.type: Easing.OutBack } }

                    // Full-size render scaled into the card
                    Item {
                        width: 1920; height: 1080
                        scale: frame.width / 1920
                        transformOrigin: Item.TopLeft
                        Loader {
                            anchors.fill: parent
                            Component.onCompleted: setSource("../lock/" + card.modelData.file, { lock: fake })
                        }
                    }
                }
                Row {
                    anchors.top: frame.bottom
                    anchors.topMargin: 8
                    spacing: 8
                    Text { text: card.modelData.name; color: card.chosen ? Theme.clock : Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; font.weight: Font.DemiBold }
                    Text { text: card.modelData.about; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4; anchors.baseline: parent.children[0].baseline }
                }
                MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: LockStyle.set(card.modelData.id) }
            }
        }
    }
}
