import QtQuick
import Quickshell
import Quickshell.Widgets
import "../common"
import "../services"

// Screen time: the selected day's total, the last 7 days as bars, a month
// heatmap, an hour-by-hour histogram and the top apps.
// Click a bar or a heatmap day to look at that day.
Item {
    id: root

    property date selected: new Date()
    readonly property string selKey: ScreenTime.key(selected)
    readonly property int rev: ScreenTime.revision

    Component.onCompleted: { ScreenTime.commit(); ScreenTime.loadHistory(); }

    function dayFor(d) { rev; return ScreenTime.dayData(ScreenTime.key(d)); }
    function fmt(secs) {
        const m = Math.round(secs / 60);
        return m < 60 ? m + "m" : Math.floor(m / 60) + "h " + String(m % 60).padStart(2, "0") + "m";
    }

    readonly property var selDay: { rev; return ScreenTime.dayData(selKey); }
    readonly property real selTotal: ScreenTime.total(selDay)
    readonly property var last7: {
        rev;
        const out = [];
        for (let i = 6; i >= 0; i--) {
            const d = new Date(selected);
            d.setDate(d.getDate() - i);
            out.push({ date: d, total: ScreenTime.total(ScreenTime.dayData(ScreenTime.key(d))) });
        }
        return out;
    }
    readonly property real weekAvg: last7.reduce((a, b) => a + b.total, 0) / 7
    readonly property real yesterday: last7.length >= 2 ? last7[5].total : 0
    readonly property real maxDay: Math.max(1, ...last7.map(d => d.total))
    readonly property var apps: {
        if (!selDay) return [];
        return Object.entries(selDay.apps).sort((a, b) => b[1] - a[1]).slice(0, 6);
    }
    readonly property var hours: selDay ? selDay.hours : new Array(24).fill(0)
    readonly property real maxHour: Math.max(60, ...hours)

    // ---- Top row: totals ----------------------------------------------------
    Row {
        id: stats
        width: parent.width
        spacing: 10
        Repeater {
            model: [
                { big: root.fmt(root.selTotal), small: root.selKey === ScreenTime.dayKey ? "Today" : Qt.formatDate(root.selected, "dddd, d MMM") },
                { big: root.fmt(root.weekAvg), small: "Daily average (7 days)" },
                { big: (root.selTotal >= root.yesterday ? "+" : "−") + root.fmt(Math.abs(root.selTotal - root.yesterday)), small: "vs. the day before" }
            ]
            Rectangle {
                required property var modelData
                required property int index
                width: index === 0 ? stats.width * 0.4 : (stats.width * 0.6 - 20) / 2
                height: 70; radius: 16
                color: index === 0 ? Theme.surfaceHi : Theme.surface
                Column {
                    anchors.centerIn: parent
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.big; color: index === 0 ? Theme.clock : Theme.fg; font.family: "JetBrains Mono"; font.pixelSize: index === 0 ? 30 : 20; font.weight: Font.Bold }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.small; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
                }
            }
        }
    }

    // ---- Middle: week bars + month heatmap ------------------------------------
    Row {
        id: middle
        anchors.top: stats.bottom
        anchors.topMargin: 12
        width: parent.width
        height: 200
        spacing: 12

        Rectangle {
            width: parent.width - heat.width - 12; height: parent.height; radius: 16
            color: Theme.surface
            Row {
                anchors.fill: parent
                anchors.margins: 14
                anchors.bottomMargin: 30
                spacing: 10
                Repeater {
                    model: root.last7
                    Item {
                        required property var modelData
                        readonly property bool isSel: ScreenTime.key(modelData.date) === root.selKey
                        width: (parent.width - 60) / 7; height: parent.height
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width; radius: 8
                            height: Math.max(4, parent.height * modelData.total / root.maxDay)
                            color: parent.isSel ? Theme.clock : Theme.surfaceHi
                            Behavior on height { NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } }
                        }
                        Text {
                            anchors.top: parent.bottom
                            anchors.topMargin: 6
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDate(modelData.date, "ddd")
                            color: parent.isSel ? Theme.fg : Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 5
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selected = modelData.date }
                    }
                }
            }
        }

        Rectangle {
            id: heat
            width: 280; height: parent.height; radius: 16
            color: Theme.surface
            MonthCalendar {
                anchors.fill: parent
                anchors.margins: 10
                selected: root.selected
                heat: d => { root.rev; return ScreenTime.total(ScreenTime.dayData(ScreenTime.key(d))) / (8 * 3600); }
                onDaySelected: d => root.selected = d
            }
        }
    }

    // ---- Bottom: hourly histogram + top apps ----------------------------------
    Row {
        anchors.top: middle.bottom
        anchors.topMargin: 12
        anchors.bottom: parent.bottom
        width: parent.width
        spacing: 12

        Rectangle {
            width: parent.width * 0.5; height: parent.height; radius: 16
            color: Theme.surface
            Text { x: 14; y: 10; text: "By hour"; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
            Row {
                anchors.fill: parent
                anchors.margins: 14
                anchors.topMargin: 32
                anchors.bottomMargin: 24
                spacing: 3
                Repeater {
                    model: 24
                    Item {
                        required property int index
                        width: (parent.width - 23 * 3) / 24; height: parent.height
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width; radius: 3
                            height: Math.max(2, parent.height * root.hours[index] / root.maxHour)
                            color: root.hours[index] > 0 ? Theme.clock : Theme.surfaceHi
                            Behavior on height { NumberAnimation { duration: Anim.slow } }
                        }
                        Text {
                            visible: index % 6 === 0
                            anchors.top: parent.bottom
                            anchors.topMargin: 4
                            text: String(index).padStart(2, "0") + ":00"
                            color: Theme.fgDim; font.family: Theme.font; font.pixelSize: 9
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width * 0.5 - 12; height: parent.height; radius: 16
            color: Theme.surface
            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6
                Text { text: "Apps"; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
                Repeater {
                    model: root.apps
                    Item {
                        required property var modelData
                        width: parent.width; height: 24
                        IconImage { id: ico; implicitSize: 18; anchors.verticalCenter: parent.verticalCenter; source: ScreenTime.iconFor(modelData[0]) }
                        Text {
                            id: nm
                            anchors.left: ico.right; anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 110; elide: Text.ElideRight
                            text: ScreenTime.prettyName(modelData[0])
                            color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                        }
                        Rectangle {
                            anchors.left: nm.right; anchors.leftMargin: 8
                            anchors.right: dur.left; anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            height: 6; radius: 3
                            color: Theme.surfaceHi
                            Rectangle {
                                height: parent.height; radius: 3
                                width: parent.width * modelData[1] / Math.max(1, root.apps[0][1])
                                color: Theme.clock
                                Behavior on width { NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } }
                            }
                        }
                        Text {
                            id: dur
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.fmt(modelData[1])
                            color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4
                        }
                    }
                }
                Text {
                    visible: root.apps.length === 0
                    text: "Nothing recorded for this day yet"
                    color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                }
            }
        }
    }
}
