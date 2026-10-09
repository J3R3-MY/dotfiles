import QtQuick
import Quickshell
import "../common"

// Month grid, Monday first. Scroll or the arrows change month; clicking the
// title jumps back to today. Optional `heat` colours days by a 0..1 value
// (used by the screen-time heatmap) and `selected`/`daySelected` make it pickable.
Item {
    id: root

    property int monthOffset: 0
    property var heat: null              // function(Date) -> 0..1, or null
    property var selected: null          // Date
    signal daySelected(date d)

    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property date today: clock.date
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
    readonly property date gridStart: {
        const d = new Date(shown);
        d.setDate(1 - ((shown.getDay() + 6) % 7));
        return d;
    }

    implicitWidth: 300
    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: 8

        Item {
            width: parent.width; height: 28
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(root.shown, "MMMM yyyy")
                color: Theme.clock; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.DemiBold
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
                    width: grid.cell; height: 22
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4
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
                    readonly property bool isSelected: root.selected !== null && d.toDateString() === root.selected.toDateString()
                    readonly property real heatValue: root.heat ? root.heat(d) : 0
                    width: grid.cell; height: grid.cell * 0.8

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 4; height: width; radius: root.heat ? 6 : width / 2
                        color: day.isToday && !root.heat ? Theme.clock
                             : root.heat && day.heatValue > 0 ? Qt.rgba(Theme.clock.r, Theme.clock.g, Theme.clock.b, 0.15 + 0.85 * day.heatValue)
                             : "transparent"
                        border.width: day.isSelected || (root.heat && day.isToday) ? 2 : 0
                        border.color: Theme.fg
                    }
                    Text {
                        anchors.centerIn: parent
                        text: day.d.getDate()
                        color: (day.isToday && !root.heat) || day.heatValue > 0.55 ? Theme.onPill : Theme.fg
                        opacity: day.inMonth ? 1 : 0.3
                        font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.heat !== null
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.daySelected(day.d)
                    }
                }
            }
        }
    }

    WheelHandler { onWheel: e => root.monthOffset += e.angleDelta.y > 0 ? -1 : 1 }
}
