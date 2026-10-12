import QtQuick
import Quickshell
import Quickshell.Widgets
import "../common"
import "../services"

// Network panel (click the network pill, the ports pill, or $mod+Shift+n).
//   Traffic – live ↓/↑ chart (5/15/30 min), link details, per-app usage
//   Health  – laptop → router → internet with latency per leg, score,
//             outage log and an on-demand speed test
//   VPN     – NetworkManager VPN/WireGuard profiles, Tailscale, Mullvad
//   Ports   – listening dev servers with a kill button
DropPanel {
    id: root

    required property string screenName
    open: Fluid.netOpen && Fluid.netScreen === screenName
    readonly property string tab: Fluid.netTab

    onOpenChanged: {
        NetStats.detailed = open;
        if (open) { Vpn.refresh(); Ports.refresh(); }
    }

    width: 460
    height: Math.min(640, content.implicitHeight + 32)


    component Node: Column {
        property string icon; property string name
        width: 70
        Glyph { anchors.horizontalCenter: parent.horizontalCenter; text: parent.icon; size: 22 }
        Label { size: "xs"; dim: true; anchors.horizontalCenter: parent.horizontalCenter; text: parent.name }
    }

    component Leg: Column {
        id: legRoot
        property var leg
        width: 120
        spacing: 4
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: parent.leg.last >= 0 ? Math.round(parent.leg.last) + " ms" : "—"
            color: parent.leg.loss > 0.2 ? Theme.urgent : Theme.fg
            font.pixelSize: Theme.fontSize - 3
        }
        // sparkline of the last samples
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            height: 18
            spacing: 1
            Repeater {
                model: legRoot.leg.samples.slice(-30)
                Rectangle {
                    required property real modelData
                    anchors.bottom: parent.bottom
                    width: 3
                    height: modelData < 0 ? 18 : Math.max(2, Math.min(18, modelData / 8))
                    color: modelData < 0 ? Theme.urgent : Theme.clock
                    opacity: 0.8
                }
            }
        }
        Label {
            dim: true
            anchors.horizontalCenter: parent.horizontalCenter
            text: "jitter " + Math.round(parent.leg.jitter) + " · loss " + Math.round(parent.leg.loss * 100) + "%"
            font.pixelSize: 9
        }
    }

    component VpnRow: Rectangle {
        id: vr
        property string title; property string sub; property bool on: false
        signal clicked()
        width: parent.width; height: 50; radius: 14
        color: on ? Theme.accent : (va.containsMouse ? Theme.surfaceHi : Theme.surface)
        Behavior on color { ColorAnimation { duration: Anim.fast } }
        Glyph { id: vg; x: 14; anchors.verticalCenter: parent.verticalCenter; text: parent.on ? Icons.g(0xf0483) : Icons.g(0xf099c); color: parent.on ? Theme.onPill : Theme.fg }
        Column {
            anchors.left: vg.right; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter
            Label { text: vr.title; color: vr.on ? Theme.onPill : Theme.fg }
            Label { text: vr.sub; color: vr.on ? Theme.onPill : Theme.fgDim; size: "xs" }
        }
        MouseArea { id: va; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: !Vpn.busy; onClicked: parent.clicked() }
    }

    component PortRow: Rectangle {
        id: pr
        property var p
        property bool armed: false
        width: parent.width; height: 54; radius: 14
        color: Theme.surface
        Text {
            id: portNum
            x: 14; anchors.verticalCenter: parent.verticalCenter
            text: ":" + pr.p.port
            color: Theme.clock; font.family: "JetBrains Mono"; font.pixelSize: Theme.fontSize; font.weight: Font.Bold
        }
        Column {
            anchors.left: portNum.right; anchors.leftMargin: 14
            anchors.right: killBtn.left; anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            // what it is, then who can reach it and how it was started
            Label { width: parent.width; elide: Text.ElideRight; text: [pr.p.name, pr.p.purpose, pr.p.pid ? "pid " + pr.p.pid : ""].filter(t => t).join("  ·  "); size: "sm" }
            Label {
                width: parent.width; elide: Text.ElideRight
                text: [pr.p.scope, pr.p.proto, pr.p.cwd ? pr.p.cwd + "  $ " + pr.p.cmd : pr.p.desc].filter(t => t).join("  ·  ")
                color: pr.p.reach === 2 ? Theme.clock : Theme.fgDim; size: "xs"
            }
        }
        Button {
            id: killBtn
            visible: pr.p.pid > 0
            anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
            width: pr.armed ? 72 : 30; height: 30
            text: pr.armed ? "Stop?" : Icons.close; font.pixelSize: Theme.fontSize - 3
            baseColor: pr.armed ? Theme.urgent : "transparent"
            hoverColor: pr.armed ? Theme.urgent : Theme.surfaceHi
            Behavior on width { NumberAnimation { duration: Anim.fast } }
            Timer { id: disarm; interval: 3000; onTriggered: pr.armed = false }
            onClicked: { if (!pr.armed) { pr.armed = true; disarm.restart(); } else Ports.kill(pr.p); }
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 16
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: content
            width: parent.width
            spacing: 14

            // Header: name + state, tabs
            Row {
                width: parent.width
                spacing: 10
                Glyph { text: Network.type === "ethernet" ? Icons.ethernet : Icons.wifi; size: 20; color: Theme.clock; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Label { text: Network.connected ? Network.name : "Disconnected"; font.weight: Font.DemiBold }
                    Label { size: "xs"; dim: true; text: (Network.connected ? "connected" : "offline") + (Vpn.connected ? "  ·  VPN " + Vpn.label : "") }
                }
            }
            Row {
                spacing: 6
                Repeater {
                    model: [{ id: "traffic", t: "Traffic" }, { id: "health", t: "Health" }, { id: "vpn", t: "VPN" }, { id: "ports", t: "Ports" + (Ports.count ? " " + Ports.count : "") }]
                    Chip { required property var modelData; text: modelData.t; on: root.tab === modelData.id; onClicked: Fluid.netTab = modelData.id }
                }
            }

            // ================= Traffic =================
            Column {
                id: traffic
                visible: root.tab === "traffic"
                width: parent.width
                spacing: 12
                property int window: 5          // minutes shown in the chart

                Row {
                    spacing: 24
                    Column { Label { size: "xs"; dim: true; text: "Download" } Text { text: "↓ " + NetStats.mbps(NetStats.down) + " Mbps"; color: Theme.clock; font.family: "JetBrains Mono"; font.pixelSize: 22; font.weight: Font.Bold } }
                    Column { Label { size: "xs"; dim: true; text: "Upload" } Text { text: "↑ " + NetStats.mbps(NetStats.up) + " Mbps"; color: Theme.network; font.family: "JetBrains Mono"; font.pixelSize: 22; font.weight: Font.Bold } }
                }

                Rectangle {
                    id: chartBox
                    width: parent.width; height: 120; radius: 14
                    color: Theme.surface
                    readonly property var pts: {
                        const cut = Date.now() - traffic.window * 60000;
                        return NetStats.history.filter(p => p.t >= cut);
                    }
                    readonly property real peak: Math.max(1024, ...pts.map(p => Math.max(p.down, p.up)))
                    onPtsChanged: chart.requestPaint()
                    Canvas {
                        id: chart
                        anchors.fill: parent
                        anchors.margins: 10
                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            const pts = chartBox.pts, n = pts.length;
                            if (n < 2) return;
                            const draw = (key, col, fill) => {
                                ctx.beginPath();
                                for (let i = 0; i < n; i++) {
                                    const x = i / (n - 1) * width, y = height - pts[i][key] / chartBox.peak * height;
                                    i ? ctx.lineTo(x, y) : ctx.moveTo(x, y);
                                }
                                if (fill) { ctx.lineTo(width, height); ctx.lineTo(0, height); ctx.closePath(); ctx.globalAlpha = 0.25; ctx.fillStyle = col; ctx.fill(); ctx.globalAlpha = 1; }
                                else { ctx.lineWidth = 2; ctx.strokeStyle = col; ctx.stroke(); }
                            };
                            draw("down", String(Theme.clock), true); draw("down", String(Theme.clock), false);
                            draw("up", String(Theme.network), false);
                        }
                    }
                    Label { size: "xs"; dim: true; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8; text: "peak " + NetStats.mbps(chartBox.peak) + " Mbps" }
                }
                Row {
                    spacing: 6
                    Repeater {
                        model: [5, 15, 30]
                        Chip { required property int modelData; text: modelData + " min"; on: traffic.window === modelData; onClicked: traffic.window = modelData }
                    }
                }

                Grid {
                    columns: 2
                    columnSpacing: 20; rowSpacing: 6
                    readonly property var d: NetStats.details
                    Repeater {
                        model: [
                            ["SSID", parent.d.ssid], ["Signal", parent.d.signal], ["Link rate", parent.d.bitrate],
                            ["Band", parent.d.freq ? (parseFloat(parent.d.freq) > 4900 ? "5/6 GHz" : "2.4 GHz") + " (" + parent.d.freq + " MHz)" : ""],
                            ["IP", parent.d.ip], ["Gateway", parent.d.gateway], ["DNS", parent.d.dns], ["Interface", parent.d.iface],
                            ["MAC", parent.d.mac], ["MTU", parent.d.mtu],
                            ["Total ↓ / ↑", NetStats.fmt(NetStats.totalDown) + " / " + NetStats.fmt(NetStats.totalUp)]
                        ].filter(r => r[1])
                        Row {
                            required property var modelData
                            width: 200
                            Label { size: "xs"; dim: true; width: 70; text: modelData[0] }
                            Label { width: 130; elide: Text.ElideRight; text: modelData[1]; font.pixelSize: Theme.fontSize - 4 }
                        }
                    }
                }

                Label { size: "xs"; dim: true; text: "Apps right now"; visible: NetStats.apps.length > 0 }
                Repeater {
                    model: NetStats.apps
                    Row {
                        required property var modelData
                        width: parent.width
                        Label { width: parent.width - 160; elide: Text.ElideRight; text: modelData.name; font.pixelSize: Theme.fontSize - 3 }
                        Label { size: "xs"; dim: true; width: 96; text: "↓ " + NetStats.mbps(modelData.down) + " Mbps" }
                        Label { size: "xs"; dim: true; width: 96; text: "↑ " + NetStats.mbps(modelData.up) + " Mbps" }
                    }
                }
            }

            // ================= Health =================
            Column {
                visible: root.tab === "health"
                width: parent.width
                spacing: 12

                Row {
                    spacing: 14
                    Ring {
                        value: Health.score / 100
                        text: String(Health.score)
                        color: Health.score >= 80 ? Theme.cpu : Health.score >= 50 ? Theme.battery : Theme.urgent
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 300
                        Label { text: "Connection score"; font.weight: Font.DemiBold }
                        Label { size: "xs"; dim: true; width: parent.width; wrapMode: Text.Wrap; text: Health.verdict; font.pixelSize: Theme.fontSize - 3 }
                    }
                }

                // laptop —— router —— internet, latency on each leg
                Item {
                    width: parent.width; height: 92
                    Row {
                        anchors.centerIn: parent
                        spacing: 0
                        Node { icon: Icons.g(0xf109); name: "This PC" }
                        Leg { leg: Health.lan }
                        Node { icon: Icons.g(0xf0453); name: Health.gateway || "Router" }
                        Leg { leg: Health.wan }
                        Node { icon: Icons.g(0xf0ac); name: "Internet" }
                    }
                }

                Row {
                    spacing: 10
                    Chip { text: Health.testing ? "Testing…" : "Run speed test"; on: Health.testing; onClicked: Health.speedTest() }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Health.speedDown >= 0
                        text: "↓ " + NetStats.mbit(Health.speedDown) + " Mbps   ↑ " + NetStats.mbit(Health.speedUp) + " Mbps"
                        font.pixelSize: Theme.fontSize - 3
                    }
                }

                Label { size: "xs"; dim: true; text: Health.outages.length ? "Outages" : "No outages recorded" }
                Repeater {
                    model: Health.outages.slice().reverse().slice(0, 6)
                    Row {
                        required property var modelData
                        spacing: 10
                        Label { text: Qt.formatDateTime(new Date(modelData.start), "ddd d MMM HH:mm"); font.pixelSize: Theme.fontSize - 4 }
                        Label { size: "xs"; dim: true; text: Math.max(1, Math.round((modelData.end - modelData.start) / 60000)) + " min" }
                        Label { size: "xs"; dim: true; text: modelData.leg === "lan" ? "Wi-Fi / router" : "internet / ISP"; color: Theme.urgent }
                    }
                }
            }

            // ================= VPN =================
            Column {
                visible: root.tab === "vpn"
                width: parent.width
                spacing: 8

                Label { size: "xs"; dim: true
                    visible: !Vpn.available
                    width: parent.width; wrapMode: Text.Wrap
                    text: "No VPN found. Add WireGuard/OpenVPN profiles to NetworkManager, or install Tailscale or Mullvad."
                }

                Repeater {
                    model: Vpn.profiles
                    VpnRow {
                        required property var modelData
                        title: modelData.name
                        sub: (modelData.type === "wireguard" ? "WireGuard" : "VPN") + " · NetworkManager · " + (modelData.active ? "connected" : "tap to connect")
                        on: modelData.active
                        onClicked: Vpn.toggleProfile(modelData)
                    }
                }
                VpnRow {
                    visible: Vpn.tailscale
                    title: "Tailscale"
                    sub: Vpn.tailscaleUp ? "up" + (Vpn.tailscaleExit ? " · exit node " + Vpn.tailscaleExit : "") : "down · tap to connect"
                    on: Vpn.tailscaleUp
                    onClicked: Vpn.setTailscale(!Vpn.tailscaleUp)
                }
                Flow {
                    visible: Vpn.tailscaleUp && Vpn.exitNodes.length > 0
                    width: parent.width
                    spacing: 6
                    Label { size: "xs"; dim: true; text: "Exit node:"; height: 28; verticalAlignment: Text.AlignVCenter }
                    Chip { text: "none"; on: !Vpn.tailscaleExit; onClicked: Vpn.setExitNode("") }
                    Repeater {
                        model: Vpn.exitNodes
                        Chip { required property var modelData; text: modelData.name + (modelData.online ? "" : " (off)"); on: Vpn.tailscaleExit === modelData.name; onClicked: Vpn.setExitNode(modelData.id) }
                    }
                }
                VpnRow {
                    visible: Vpn.mullvad
                    title: "Mullvad"
                    sub: Vpn.mullvadUp ? "connected" + (Vpn.mullvadWhere ? " · " + Vpn.mullvadWhere : "") : "tap to connect"
                    on: Vpn.mullvadUp
                    onClicked: Vpn.setMullvad(!Vpn.mullvadUp)
                }
            }

            // ================= Ports =================
            Column {
                visible: root.tab === "ports"
                width: parent.width
                spacing: 6
                property bool showOther: false

                Label { size: "xs"; dim: true; visible: Ports.count === 0; text: "Nothing of yours is listening right now" }

                Repeater { model: Ports.dev; PortRow { required property var modelData; p: modelData } }

                Chip {
                    visible: Ports.ports.length > Ports.count
                    text: (parent.showOther ? "Hide" : "Show") + " apps & system (" + (Ports.ports.length - Ports.count) + ")"
                    onClicked: parent.showOther = !parent.showOther
                }
                Repeater {
                    model: parent.showOther ? Ports.ports.filter(p => p.kind !== "dev") : []
                    PortRow { required property var modelData; p: modelData; opacity: 0.75 }
                }
            }
        }
    }
}
