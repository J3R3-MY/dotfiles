import QtQuick
import Quickshell
import "../common"

// Month calendar (replaces waybar's clock tooltip calendar).
// Scroll or use the arrows to change month, click the title to jump to today.
Item {
    id: root

    SystemClock { id: clock; precision: SystemClock.Minutes }

    property int monthOffset: 0
    readonly property date today: clock.date
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
    // Monday-first grid start
    readonly property date gridStart: {
        const d = new Date(shown);
        d.setDate(1 - ((shown.getDay() + 6) % 7));
        return d;
    }

    Keys.onEscapePressed: Fluid.closeAll()
    Keys.onLeftPressed: monthOffset--
    Keys.onRightPressed: monthOffset++
    Component.onCompleted: forceActiveFocus()

    Column {
        anchors.fill: parent
        spacing: 10

        Text {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.fg; font.family: Theme.font; font.pixelSize: 40; font.weight: Font.Light
        }

        Item {
            width: parent.width; height: 28
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(root.shown, "MMMM yyyy")
                color: Theme.clock; font.family: Theme.font; font.pixelSize: Theme.fontSize + 1; font.weight: Font.DemiBold
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.monthOffset = 0 }
            }
            Row {
                anchors.right: parent.right
                spacing: 4
                Repeater {
                    model: [{ t: "‹", d: -1 }, { t: "›", d: 1 }]
                    Rectangle {
                        required property var modelData
                        width: 28; height: 28; radius: 14
                        color: nav.containsMouse ? Theme.surfaceHi : "transparent"
                        Text { anchors.centerIn: parent; text: parent.modelData.t; color: Theme.fg; font.pixelSize: 20 }
                        MouseArea { id: nav; anchors.fill: parent; hoverEnabled: true; onClicked: root.monthOffset += parent.modelData.d }
                    }
                }
            }
        }

        Grid {
            id: grid
            columns: 7
            width: parent.width
            readonly property real cell: width / 7

            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                Text {
                    required property string modelData
                    width: grid.cell; height: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                }
            }

            Repeater {
                model: 42
                Item {
                    id: day
                    required property int index
                    readonly property date d: new Date(root.gridStart.getFullYear(), root.gridStart.getMonth(), root.gridStart.getDate() + index)
                    readonly property bool inMonth: d.getMonth() === root.shown.getMonth()
                    readonly property bool isToday: d.toDateString() === root.today.toDateString()
                    width: grid.cell; height: 34

                    Rectangle {
                        anchors.centerIn: parent
                        width: 30; height: 30; radius: 15
                        color: day.isToday ? Theme.clock : "transparent"
                        scale: day.isToday ? 1 : 0.6
                        Behavior on scale { NumberAnimation { duration: Anim.normal; easing.type: Easing.OutBack } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: day.d.getDate()
                        color: day.isToday ? Theme.onPill : Theme.fg
                        opacity: day.inMonth ? 1 : 0.3
                        font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                    }
                }
            }
        }
    }

    WheelHandler { onWheel: e => root.monthOffset += e.angleDelta.y > 0 ? -1 : 1 }
}
