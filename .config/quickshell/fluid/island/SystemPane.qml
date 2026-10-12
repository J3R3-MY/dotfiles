import QtQuick
import Quickshell
import Quickshell.Io
import "../common"
import "../services"

// Dashboard "System" tab: liquid gauges for CPU, memory and temperatures
// (SysStats) and the busiest processes (ps, only while shown).
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

    // Busiest processes
    property var procs: []
    Process {
        id: ps
        // name last: it can contain spaces ("Isolated Web Co")
        command: ["ps", "-eo", "pid=,pcpu=,rss=,comm=", "--sort=-pcpu"]
        stdout: StdioCollector {
            // ps itself is always busy while it measures: leave it out
            onStreamFinished: root.procs = text.trim().split("\n").map(l => {
                const f = l.trim().split(/\s+/);
                return { pid: f[0], cpu: parseFloat(f[1]), mem: parseInt(f[2]) / 1024, name: f.slice(3).join(" ") };
            }).filter(p => p.name !== "ps").slice(0, 10)
        }
    }
    Timer { interval: 2000; repeat: true; triggeredOnStart: true; running: root.shown; onTriggered: ps.running = true }

    Rectangle {
        anchors.top: cardRow.bottom; anchors.topMargin: 12
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
