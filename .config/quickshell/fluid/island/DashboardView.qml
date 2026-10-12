import QtQuick
import QtQuick.Shapes
import Quickshell
import "../common"
import "../services"

// Clock dashboard (click the clock / $mod+c). Two tabs:
//   Today       – calendar, big clock with the next 24 h of weather around it,
//                 current conditions and a 7-day strip
//   System      – CPU, memory, temperatures, top processes (SystemPane.qml)
Item {
    id: root

    property string tab: "today"

    Keys.onEscapePressed: Fluid.closeAll()
    Keys.onTabPressed: tab = tab === "today" ? "system" : "today"
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
            model: [{ id: "today", t: "Today" }, { id: "system", t: "System" }]
            Chip {
                required property var modelData
                text: modelData.t
                on: root.tab === modelData.id
                size: Theme.fontSize - 2
                onClicked: root.tab = modelData.id
            }
        }
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
            // a flat ellipse = the ring seen from a low angle
            readonly property real ry: Math.min(height / 2 - 34, rx * 0.3)
            // ring centre a bit below the clock so the front bubbles clear the date
            readonly property real cy: height / 2 + 30
            readonly property var points: Weather.hourly.filter((h, i) => i % 3 === 0).slice(0, 8)
            // the ring is seen at an angle: it rocks slowly back and forth, and
            // bubbles at the back (top) are smaller and fainter than the front
            property real spin: -0.3
            SequentialAnimation on spin {
                running: today.visible
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 9000; easing.type: Easing.InOutSine }
                NumberAnimation { to: -0.3; duration: 9000; easing.type: Easing.InOutSine }
            }

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
                        ctx.arc(width / 2 + centre.rx * Math.cos(a), centre.cy + centre.ry * Math.sin(a), 1.2, 0, 2 * Math.PI);
                        ctx.fill();
                    }
                }
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                Connections { target: Theme; function onFgDimChanged() { orbit.requestPaint(); } }
            }

            Column {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -20
                z: 0.45                     // bubbles at the back pass behind the clock
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
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM") + (Weather.city ? "  ·  " + Weather.city : "")
                    dim: true
                }
            }

            // Forecast every 3 h, starting at the bottom and going clockwise
            Repeater {
                model: centre.points
                Rectangle {
                    id: bubble
                    required property var modelData
                    required property int index
                    readonly property real angle: Math.PI / 2 + index / Math.max(1, centre.points.length) * 2 * Math.PI + centre.spin
                    readonly property real depth: (Math.sin(angle) + 1) / 2      // 0 = back, 1 = front
                    readonly property bool now: index === 0
                    property real intro: 0
                    x: centre.width / 2 + centre.rx * Math.cos(angle) - width / 2
                    y: centre.cy + centre.ry * Math.sin(angle) - height / 2
                    z: depth
                    width: 54; height: 64; radius: 27
                    color: now ? Theme.clock : Theme.surface
                    opacity: intro * (0.3 + 0.7 * depth)
                    scale: (0.6 + 0.4 * intro) * (0.6 + 0.4 * depth)
                    Component.onCompleted: intro = 1
                    Behavior on intro { NumberAnimation { duration: Anim.slow + index * 40; easing.type: Easing.OutBack } }
                    Column {
                        anchors.centerIn: parent
                        spacing: 1
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(bubble.modelData.time, "HH:mm"); color: bubble.now ? Theme.onPill : Theme.fgDim; font.pixelSize: 10 }
                        Glyph { anchors.horizontalCenter: parent.horizontalCenter; text: Weather.iconFor(bubble.modelData.code, bubble.modelData.time.getHours() >= 6 && bubble.modelData.time.getHours() < 20); size: 15; color: bubble.now ? Theme.onPill : Theme.fg }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(bubble.modelData.temp) + "°"; color: bubble.now ? Theme.onPill : Theme.fg; font.pixelSize: 12 }
                    }
                }
            }
        }

        // Right: current conditions
        // First use: ask for the city instead of guessing it from the IP
        Column {
            visible: !Weather.located
            anchors.right: parent.right
            width: 250
            spacing: 8
            Label { text: "Weather for"; dim: true; size: "sm" }
            Rectangle {
                width: parent.width; height: 40; radius: 14
                color: Theme.surfaceHi
                TextInput {
                    id: cityInput
                    anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                    Keys.onReturnPressed: Weather.setCity(text)
                    Text { visible: !cityInput.text; anchors.verticalCenter: parent.verticalCenter; text: "Your city, then Enter"; color: Theme.fgDim; font: cityInput.font }
                }
            }
        }

        Column {
            id: current
            visible: Weather.located
            anchors.right: parent.right
            anchors.verticalCenter: cal.verticalCenter
            width: 180
            spacing: 8

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                Glyph { text: Weather.icon; size: 18; anchors.verticalCenter: parent.verticalCenter }
                Label { text: Weather.summary; anchors.verticalCenter: parent.verticalCenter }
            }
            Item { width: 1; height: 6 }
            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 2
                columnSpacing: 22
                rowSpacing: 10
                Ring { value: Math.min(1, Weather.wind / 60); text: Math.round(Weather.wind); label: "wind km/h" }
                Ring { value: Weather.humidity / 100; text: Weather.humidity + "%"; label: "humidity"; color: Theme.network }
                Ring { value: Weather.rainChance / 100; text: Weather.rainChance + "%"; label: "rain"; color: Theme.audio }
                Ring { value: Math.max(0, Math.min(1, (Weather.feels + 10) / 50)); text: Math.round(Weather.feels) + "°"; label: "feels like"; color: Theme.battery }
            }
        }

        // Faint waves flowing behind the 7-day strip: each line is a static
        // sine path two periods wide that slides by one period and loops
        Item {
            id: waves
            anchors.verticalCenter: week.verticalCenter
            width: parent.width; height: week.height + 30
            clip: true
            readonly property real period: width / 2
            Repeater {
                model: [{ amp: 10, ph: 0, ms: 9000, a: 0.22 }, { amp: 14, ph: 2, ms: 13000, a: 0.14 }, { amp: 7, ph: 4, ms: 7000, a: 0.1 }]
                Shape {
                    required property var modelData
                    width: waves.width + waves.period; height: waves.height
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Qt.alpha(Theme.clock, modelData.a)
                        strokeWidth: 1.5
                        PathPolyline {
                            path: {
                                const pts = [];
                                for (let x = 0; x <= waves.width + waves.period; x += 6)
                                    pts.push(Qt.point(x, waves.height / 2 + modelData.amp * Math.sin(x / waves.period * 2 * Math.PI + modelData.ph)));
                                return pts;
                            }
                        }
                    }
                    NumberAnimation on x { from: 0; to: -waves.period; duration: modelData.ms; loops: Animation.Infinite; running: today.visible }
                }
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
                    color: Qt.alpha(index === 0 ? Theme.surfaceHi : Theme.surface, 0.55)
                    Column {
                        anchors.centerIn: parent
                        spacing: 3
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: index === 0 ? "Today" : Qt.formatDate(modelData.date, "ddd"); dim: true; size: "xs" }
                        Glyph { anchors.horizontalCenter: parent.horizontalCenter; text: Weather.iconFor(modelData.code, true); size: 18 }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(modelData.max) + "° / " + Math.round(modelData.min) + "°"; size: "xs" }
                    }
                }
            }
        }

        Label {
            anchors.centerIn: centre
            anchors.verticalCenterOffset: 90
            visible: Weather.located && !Weather.ready
            text: "Loading weather…"
            dim: true; size: "sm"
        }
    }

    // ---- System -------------------------------------------------------------
    SystemPane {
        anchors.top: tabs.bottom
        anchors.topMargin: 14
        anchors.bottom: parent.bottom
        width: parent.width
        shown: root.tab === "system"
        opacity: shown ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Anim.normal } }
    }
}
