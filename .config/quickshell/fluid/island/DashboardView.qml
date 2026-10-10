import QtQuick
import Quickshell
import "../common"
import "../services"

// Clock dashboard (click the clock / $mod+c). Two tabs:
//   Today       – calendar, big clock with the next 24 h of weather around it,
//                 current conditions and a 7-day strip
//   Screen time – see ScreenTimePane.qml
Item {
    id: root

    property string tab: "today"

    Keys.onEscapePressed: Fluid.closeAll()
    Keys.onTabPressed: tab = tab === "today" ? "screentime" : "today"
    Component.onCompleted: {
        forceActiveFocus();
        if (!Weather.ready) Weather.refresh();
    }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    // ---- Tabs ---------------------------------------------------------------
    Row {
        id: tabs
        spacing: 6
        Repeater {
            model: [{ id: "today", t: "Today" }, { id: "screentime", t: "Screen time" }]
            Chip {
                required property var modelData
                text: modelData.t
                on: root.tab === modelData.id
                size: Theme.fontSize - 2
                onClicked: root.tab = modelData.id
            }
        }
    }

    Text {
        anchors.right: parent.right
        anchors.verticalCenter: tabs.verticalCenter
        visible: root.tab === "today"
        text: Weather.city ? Icons.g(0xf041) + "  " + Weather.city : ""
        color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
    }

    // ---- Today --------------------------------------------------------------
    Item {
        id: today
        anchors.top: tabs.bottom
        anchors.topMargin: 14
        anchors.bottom: parent.bottom
        width: parent.width
        opacity: root.tab === "today" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Anim.normal } }

        MonthCalendar {
            id: cal
            width: 280
        }

        // Centre: clock + forecast ring
        Item {
            id: centre
            anchors.left: cal.right
            anchors.right: current.left
            anchors.top: parent.top
            anchors.bottom: week.top
            anchors.margins: 10

            readonly property real rx: width / 2 - 34
            readonly property real ry: height / 2 - 30
            readonly property var points: Weather.hourly.filter((h, i) => i % 3 === 0).slice(0, 8)

            // Dotted ellipse the forecast sits on
            Canvas {
                id: orbit
                anchors.fill: parent
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = String(Theme.fgDim);
                    for (let i = 0; i < 90; i++) {
                        const a = i / 90 * 2 * Math.PI;
                        ctx.globalAlpha = 0.35;
                        ctx.beginPath();
                        ctx.arc(width / 2 + centre.rx * Math.cos(a), height / 2 + centre.ry * Math.sin(a), 1.2, 0, 2 * Math.PI);
                        ctx.fill();
                    }
                }
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                Connections { target: Theme; function onFgDimChanged() { orbit.requestPaint(); } }
            }

            Column {
                anchors.centerIn: parent
                spacing: 2
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    Text {
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: Theme.fg; font.family: "JetBrains Mono"; font.pixelSize: 64; font.weight: Font.Bold
                    }
                    Text {
                        anchors.baseline: parent.children[0].baseline
                        text: Qt.formatDateTime(clock.date, ":ss")
                        color: Theme.clock; font.family: "JetBrains Mono"; font.pixelSize: 24
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                }
            }

            // Forecast every 3 h, starting at the bottom and going clockwise
            Repeater {
                model: centre.points
                Rectangle {
                    id: bubble
                    required property var modelData
                    required property int index
                    readonly property real angle: Math.PI / 2 + index / Math.max(1, centre.points.length) * 2 * Math.PI
                    readonly property bool now: index === 0
                    x: centre.width / 2 + centre.rx * Math.cos(angle) - width / 2
                    y: centre.height / 2 + centre.ry * Math.sin(angle) - height / 2
                    width: 54; height: 64; radius: 27
                    color: now ? Theme.clock : Theme.surface
                    opacity: 0
                    scale: 0.6
                    Component.onCompleted: { opacity = 1; scale = 1; }
                    Behavior on opacity { NumberAnimation { duration: Anim.normal + index * 40 } }
                    Behavior on scale { NumberAnimation { duration: Anim.slow + index * 40; easing.type: Easing.OutBack } }
                    Column {
                        anchors.centerIn: parent
                        spacing: 1
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(bubble.modelData.time, "HH:mm"); color: bubble.now ? Theme.onPill : Theme.fgDim; font.family: Theme.font; font.pixelSize: 10 }
                        Glyph { anchors.horizontalCenter: parent.horizontalCenter; text: Weather.iconFor(bubble.modelData.code, bubble.modelData.time.getHours() >= 6 && bubble.modelData.time.getHours() < 20); size: 15; color: bubble.now ? Theme.onPill : Theme.fg }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(bubble.modelData.temp) + "°"; color: bubble.now ? Theme.onPill : Theme.fg; font.family: Theme.font; font.pixelSize: 12 }
                    }
                }
            }
        }

        // Right: current conditions
        Column {
            id: current
            anchors.right: parent.right
            width: 250
            spacing: 8

            Text {
                anchors.right: parent.right
                text: Weather.ready ? Math.round(Weather.temp) + "°" : "—"
                color: Theme.clock; font.family: Theme.font; font.pixelSize: 56; font.weight: Font.Bold
            }
            Row {
                anchors.right: parent.right
                spacing: 8
                Glyph { text: Weather.icon; size: 18; anchors.verticalCenter: parent.verticalCenter }
                Text { text: Weather.summary; color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; anchors.verticalCenter: parent.verticalCenter }
            }
            Item { width: 1; height: 10 }
            Grid {
                anchors.right: parent.right
                columns: 2
                columnSpacing: 22
                rowSpacing: 10
                Ring { value: Math.min(1, Weather.wind / 60); text: Math.round(Weather.wind); label: "wind km/h" }
                Ring { value: Weather.humidity / 100; text: Weather.humidity + "%"; label: "humidity"; color: Theme.network }
                Ring { value: Weather.rainChance / 100; text: Weather.rainChance + "%"; label: "rain"; color: Theme.audio }
                Ring { value: Math.max(0, Math.min(1, (Weather.feels + 10) / 50)); text: Math.round(Weather.feels) + "°"; label: "feels like"; color: Theme.battery }
            }
        }

        // Bottom: 7-day strip
        Row {
            id: week
            anchors.bottom: parent.bottom
            width: parent.width
            height: 74
            spacing: 8
            Repeater {
                model: Weather.daily
                Rectangle {
                    required property var modelData
                    required property int index
                    width: (week.width - 6 * 8) / 7; height: week.height
                    radius: 14
                    color: index === 0 ? Theme.surfaceHi : Theme.surface
                    Column {
                        anchors.centerIn: parent
                        spacing: 3
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: index === 0 ? "Today" : Qt.formatDate(modelData.date, "ddd"); color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
                        Glyph { anchors.horizontalCenter: parent.horizontalCenter; text: Weather.iconFor(modelData.code, true); size: 18 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(modelData.max) + "° / " + Math.round(modelData.min) + "°"; color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: centre
            anchors.verticalCenterOffset: 90
            visible: !Weather.ready
            text: "Loading weather…"
            color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
        }
    }

    // ---- Screen time --------------------------------------------------------
    ScreenTimePane {
        anchors.top: tabs.bottom
        anchors.topMargin: 14
        anchors.bottom: parent.bottom
        width: parent.width
        opacity: root.tab === "screentime" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Anim.normal } }
    }
}
