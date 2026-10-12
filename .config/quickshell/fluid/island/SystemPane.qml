import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "../common"
import "../services"

// Dashboard "System" tab: liquid gauges for CPU, memory and temperatures
// (SysStats), a 2-minute CPU graph and the busiest processes (ps, only while
// shown).
Item {
    id: root

    property bool shown: false

    function card(title, value, level, sub, color) { return { title: title, value: value, level: level, sub: sub, color: color }; }
    readonly property var cards: [
        card("CPU", SysStats.cpu + "%", SysStats.cpu / 100, "", Theme.cpu),
        card("Memory", SysStats.memory + "%", SysStats.memory / 100,
             SysStats.memUsedGiB.toFixed(1) + " of " + SysStats.memTotalGiB.toFixed(0) + " GB", Theme.memory),
        card("CPU temp", isNaN(SysStats.cpuTemp) ? "–" : Math.round(SysStats.cpuTemp) + "°", (SysStats.cpuTemp || 0) / 100, "package", Theme.backlight),
        card("SSD", isNaN(SysStats.diskTemp) ? "–" : Math.round(SysStats.diskTemp) + "°", (SysStats.diskTemp || 0) / 80,
             SysStats.fans.length ? "fans " + SysStats.fans.map(f => f + " rpm").join(" · ") : "", Theme.network)
    ]

    Row {
        id: cardRow
        width: parent.width
        spacing: 10
        Repeater {
            // a fixed count, not the cards array: that is rebuilt on every
            // stats tick and would recreate the gauges (restarting the waves)
            model: 4
            Rectangle {
                id: gcard
                required property int index
                readonly property var modelData: root.cards[index]
                width: (cardRow.width - 30) / 4; height: 118; radius: 18
                color: Theme.surface
                WaveGauge {
                    id: gauge
                    anchors.left: parent.left; anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    size: 92
                    value: gcard.modelData.level
                    text: gcard.modelData.value
                    color: gcard.modelData.color
                }
                Column {
                    anchors.left: gauge.right; anchors.leftMargin: 12
                    anchors.right: parent.right; anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    Text { text: gcard.modelData.title; color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; font.weight: Font.DemiBold }
                    Text { width: parent.width; wrapMode: Text.Wrap; visible: text.length > 0; text: gcard.modelData.sub; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
                }
            }
        }
    }

    // CPU over the last 2 minutes (newest on the right): filled area that
    // fades out downwards, with a brighter line on top
    Rectangle {
        id: graph
        anchors.top: cardRow.bottom; anchors.topMargin: 12
        width: parent.width; height: 120; radius: 18
        color: Theme.surface
        Text { x: 16; y: 10; text: "CPU usage · last 2 minutes"; color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3; font.weight: Font.DemiBold }
        Text { anchors.right: parent.right; anchors.rightMargin: 16; y: 10; text: SysStats.cpu + "%"; color: Theme.cpu; font.family: "JetBrains Mono"; font.pixelSize: Theme.fontSize - 3 }

        Shape {
            id: plot
            anchors.fill: parent
            anchors.topMargin: 34; anchors.bottomMargin: 10
            anchors.leftMargin: 16; anchors.rightMargin: 16
            preferredRendererType: Shape.CurveRenderer
            // the top of the graph follows the load (20 / 40 / ... / 100 %) so
            // a quiet machine doesn't draw a flat line on the floor
            readonly property int ceiling: Math.max(20, Math.ceil(Math.max(...SysStats.cpuHistory, 1) / 20) * 20)
            readonly property var line: {
                const h = SysStats.cpuHistory, n = Math.max(2, h.length);
                return h.map((v, i) => Qt.point(34 + (width - 34) * (i + 60 - n) / 59, height * (1 - Math.min(v, ceiling) / ceiling)));
            }
            // guide lines at the top and the middle, labelled on the left
            Repeater {
                model: [0, 0.5]
                Item {
                    required property real modelData
                    width: plot.width; y: plot.height * modelData
                    Rectangle { x: 34; width: parent.width - 34; height: 1; color: Qt.alpha(Theme.fg, 0.08) }
                    Text {
                        anchors.verticalCenter: parent.top
                        text: Math.round(plot.ceiling * (1 - parent.modelData)) + "%"
                        color: Theme.fgDim; font.family: "JetBrains Mono"; font.pixelSize: 9
                    }
                }
            }
            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    y1: 0; y2: plot.height
                    GradientStop { position: 0; color: Qt.alpha(Theme.cpu, 0.45) }
                    GradientStop { position: 1; color: Qt.alpha(Theme.cpu, 0) }
                }
                PathPolyline {
                    path: plot.line.length ? plot.line.concat([Qt.point(plot.width, plot.height), Qt.point(plot.line[0].x, plot.height)]) : []
                }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: Theme.cpu
                strokeWidth: 2
                joinStyle: ShapePath.RoundJoin
                capStyle: ShapePath.RoundCap
                PathPolyline { path: plot.line }
            }
        }
    }

    // Busiest processes
    property var procs: []
    Process {
        id: ps
        // name last: it can contain spaces ("Isolated Web Co")
        command: ["ps", "-eo", "pid=,pcpu=,rss=,comm=", "--sort=-pcpu"]
        stdout: StdioCollector {
            onStreamFinished: root.procs = text.trim().split("\n").slice(0, 5).map(l => {
                const f = l.trim().split(/\s+/);
                return { pid: f[0], cpu: parseFloat(f[1]), mem: parseInt(f[2]) / 1024, name: f.slice(3).join(" ") };
            })
        }
    }
    Timer { interval: 2000; repeat: true; triggeredOnStart: true; running: root.shown; onTriggered: ps.running = true }

    Rectangle {
        anchors.top: graph.bottom; anchors.topMargin: 12
        anchors.bottom: parent.bottom
        width: parent.width; radius: 18
        color: Theme.surface
        Column {
            anchors.fill: parent; anchors.margins: 14
            spacing: 4
            Row {
                width: parent.width
                Text { width: parent.width - 180; text: "Process"; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
                Text { width: 90; horizontalAlignment: Text.AlignRight; text: "CPU"; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
                Text { width: 90; horizontalAlignment: Text.AlignRight; text: "Memory"; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
            }
            Repeater {
                model: root.procs
                Row {
                    required property var modelData
                    width: parent.width
                    Text { width: parent.width - 180; elide: Text.ElideRight; text: modelData.name; color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
                    Text { width: 90; horizontalAlignment: Text.AlignRight; text: modelData.cpu.toFixed(1) + "%"; color: Theme.fg; font.family: "JetBrains Mono"; font.pixelSize: Theme.fontSize - 3 }
                    Text { width: 90; horizontalAlignment: Text.AlignRight; text: Math.round(modelData.mem) + " MB"; color: Theme.fgDim; font.family: "JetBrains Mono"; font.pixelSize: Theme.fontSize - 3 }
                }
            }
        }
    }
}
