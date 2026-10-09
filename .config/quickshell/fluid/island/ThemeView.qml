import QtQuick
import Quickshell
import Quickshell.Widgets
import "../common"
import "../services"

// Theme selector: pick a wallpaper and the whole desktop is recoloured from it
// (matugen). Arrow keys + Enter work too.
Item {
    id: root

    Keys.onEscapePressed: Fluid.closeAll()
    Keys.onLeftPressed: grid.moveCurrentIndexLeft()
    Keys.onRightPressed: grid.moveCurrentIndexRight()
    Keys.onUpPressed: grid.moveCurrentIndexUp()
    Keys.onDownPressed: grid.moveCurrentIndexDown()
    Keys.onReturnPressed: Wallpaper.apply(Wallpaper.files[grid.currentIndex])
    Component.onCompleted: {
        Wallpaper.rescan();
        forceActiveFocus();
    }

    // Header: title, status, dark/light switch
    Item {
        id: topRow
        width: parent.width
        height: 36

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Glyph { text: Icons.palette; color: Theme.clock; size: 20; anchors.verticalCenter: parent.verticalCenter }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Wallpaper.busy ? "Generating colours…" : "Wallpaper & theme"
                color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize + 1; font.weight: Font.DemiBold
            }
        }

        // Segmented dark/light control with a sliding knob
        Rectangle {
            id: seg
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 180; height: 32; radius: 16
            color: Theme.surfaceHi

            Rectangle {
                width: parent.width / 2 - 4; height: parent.height - 6; radius: height / 2
                y: 3
                x: Wallpaper.mode === "dark" ? 3 : parent.width / 2 + 1
                color: Theme.clock
                Behavior on x { NumberAnimation { duration: Anim.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.spring } }
            }
            Row {
                anchors.fill: parent
                Repeater {
                    model: [{ m: "dark", t: Icons.moon + "  Dark" }, { m: "light", t: Icons.sun + "  Light" }]
                    Item {
                        required property var modelData
                        width: seg.width / 2; height: seg.height
                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.t
                            color: Wallpaper.mode === parent.modelData.m ? Theme.onPill : Theme.fg
                            font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Wallpaper.setMode(parent.modelData.m) }
                    }
                }
            }
        }
    }

    GridView {
        id: grid
        anchors.top: topRow.bottom
        anchors.topMargin: 12
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        cellWidth: width / 4
        cellHeight: cellWidth * 0.62
        boundsBehavior: Flickable.StopAtBounds
        model: Wallpaper.files
        currentIndex: Math.max(0, Wallpaper.files.indexOf(Wallpaper.current))

        delegate: Item {
            id: cell
            required property string modelData
            required property int index
            readonly property bool isCurrent: modelData === Wallpaper.current
            readonly property bool isSelected: GridView.isCurrentItem
            width: grid.cellWidth
            height: grid.cellHeight

            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: 6
                radius: 12
                color: Theme.surfaceHi
                scale: thumbArea.containsMouse || cell.isSelected ? 1.0 : 0.95
                Behavior on scale { NumberAnimation { duration: Anim.normal; easing.type: Easing.OutBack } }

                Image {
                    anchors.fill: parent
                    source: "file://" + cell.modelData
                    sourceSize.width: 360
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Anim.normal } }
                }

                // Ring on the active wallpaper
                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: "transparent"
                    border.width: cell.isCurrent ? 3 : (cell.isSelected ? 2 : 0)
                    border.color: cell.isCurrent ? Theme.clock : Theme.fg
                    Behavior on border.width { NumberAnimation { duration: Anim.fast } }
                }
            }

            MouseArea {
                id: thumbArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { grid.currentIndex = cell.index; Wallpaper.apply(cell.modelData); }
            }
        }
    }
}
