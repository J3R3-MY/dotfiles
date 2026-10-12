import QtQuick
import Quickshell
import Quickshell.Io
import "../common"
import "../services"

// Dashboard "System" tab: CPU, memory, temperatures and fans (SysStats), a
// 2-minute CPU graph and the busiest processes (ps, only while shown).
Item {
    id: root

    property bool shown: false

    function card(title, value, sub, color) { return { title: title, value: value, sub: sub, color: color }; }
    readonly property var cards: [
        card("CPU", SysStats.cpu + "%", "", Theme.cpu),
        card("Memory", SysStats.memUsedGiB.toFixed(1) + " GB", "of " + SysStats.memTotalGiB.toFixed(0) + " GB · " + SysStats.memory + "%", Theme.memory),
        card("CPU temp", isNaN(SysStats.cpuTemp) ? "–" : Math.round(SysStats.cpuTemp) + "°", "package", Theme.backlight),
        card("SSD", isNaN(SysStats.diskTemp) ? "–" : Math.round(SysStats.diskTemp) + "°",
             SysStats.fans.length ? "fans " + SysStats.fans.map(f => f + " rpm").join(" · ") : "", Theme.network)
    ]

    Row {
        id: cardRow
        width: parent.width
        spacing: 10
        Repeater {
            model: root.cards
            Rectangle {
                required property var modelData
                width: (cardRow.width - 30) / 4; height: 96; radius: 18
                color: Theme.surface
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text { text: parent.parent.modelData.title; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
                    Text { text: parent.parent.modelData.value; color: parent.parent.modelData.color; font.family: Theme.font; font.pixelSize: Theme.fontSize + 12; font.weight: Font.DemiBold }
                    Text { visible: text.length > 0; text: parent.parent.modelData.sub; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
                }
            }
        }
    }

    // CPU over the last 2 minutes (newest on the right)
    Rectangle {
        id: graph
        anchors.top: cardRow.bottom; anchors.topMargin: 12
        width: parent.width; height: 120; radius: 18
        color: Theme.surface
        Text { x: 16; y: 10; text: "CPU · last 2 min"; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
        Row {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 12
            anchors.right: parent.right; anchors.rightMargin: 16
            height: parent.height - 40
            spacing: 2
            Repeater {
                model: SysStats.cpuHistory
                Rectangle {
                    required property var modelData
                    width: (graph.width - 32 - 59 * 2) / 60
                    height: Math.max(2, parent.height * modelData / 100)
                    anchors.bottom: parent.bottom
                    radius: 2
                    color: Theme.cpu
                    opacity: 0.85
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
            onStreamFinished: root.procs = text.trim().split("\n").slice(0, 7).map(l => {
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
