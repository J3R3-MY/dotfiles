import QtQuick
import Quickshell
import Quickshell.Widgets
import "../common"
import "../services"
import "../island"

// macOS-style control center. Opens by hovering the top-right corner, clicking
// the bluetooth/audio/backlight/network pills, or $mod+i.
// Pages (main / wifi / bluetooth / displays) slide sideways; the panel height follows
// the page so the shape morphs instead of jumping.
DropPanel {
    id: root

    required property string screenName
    open: Fluid.ccOpen && Fluid.ccScreen === screenName
    lively: true
    property string page: "main"
    // the volume pill opens straight on the Sound page (Fluid.ccPage)
    onOpenChanged: page = open ? Fluid.ccPage : "main"

    readonly property var pageList: ["main", "wifi", "bt", "display", "sound"]
    readonly property int pageIndex: Math.max(0, pageList.indexOf(page))
    readonly property var pageItems: [mainPage, wifiPage, btPage, displayPage, soundPage]

    width: page === "main" ? 400 : 480
    height: pageItems[pageIndex].implicitHeight + 32
    Behavior on width { NumberAnimation { duration: Anim.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } }

    function dismiss() { if (page === "main") Fluid.closeAll(); else page = "main"; }

    // Only the main page and one subpage sit in the row (the Row skips hidden
    // pages), so every page change is a one-page slide. `sub` keeps the last
    // subpage shown while sliding back. `slide` animates on its own so the
    // panel's width change doesn't restart the slide every frame.
    property string sub: "wifi"
    onPageChanged: if (page !== "main") sub = page
    property real slide: page === "main" ? 0 : 1
    Behavior on slide { NumberAnimation { duration: Anim.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } }

    Item {
        id: viewport
        anchors.fill: parent
        anchors.margins: 16
        clip: true

        Row {
            id: pages
            x: -root.slide * (viewport.width + 32)
            spacing: 32

            // ================= Main page =================
            Column {
                id: mainPage
                width: viewport.width
                spacing: 12

                Grid {
                    columns: 2
                    spacing: 10
                    width: parent.width

                    Toggle {
                        width: (mainPage.width - 10) / 2
                        on: Network.wifiEnabled
                        icon: Network.type === "ethernet" ? Icons.ethernet : Icons.wifi
                        title: "Wi-Fi"
                        subtitle: Network.connected ? Network.name : (Network.wifiEnabled ? "Not connected" : "Off")
                        hasMore: true
                        onClicked: Network.setWifi(!Network.wifiEnabled)
                        onMore: { Network.scan(); root.page = "wifi"; }
                    }
                    Toggle {
                        width: (mainPage.width - 10) / 2
                        on: Bt.enabled
                        icon: Bt.connected.length > 0 ? Icons.btConnected : Icons.btOn
                        title: "Bluetooth"
                        subtitle: Bt.connected.length > 0 ? Bt.connected[0].name : (Bt.enabled ? "On" : "Off")
                        hasMore: Bt.available
                        onClicked: Bt.setEnabled(!Bt.enabled)
                        onMore: root.page = "bt"
                    }
                    Toggle {
                        width: (mainPage.width - 10) / 2
                        on: Fluid.dnd
                        icon: Fluid.dnd ? Icons.bellOff : Icons.bell
                        title: "Do Not Disturb"
                        subtitle: Fluid.dnd ? "On" : "Off"
                        onClicked: Fluid.dnd = !Fluid.dnd
                    }
                    Toggle {
                        width: (mainPage.width - 10) / 2
                        on: !Audio.micMuted
                        icon: Audio.micMuted ? Icons.micOff : Icons.mic
                        title: "Microphone"
                        subtitle: Audio.micMuted ? "Muted" : "On"
                        onClicked: Audio.toggleMic()
                    }
                    Toggle {
                        width: (mainPage.width - 10) / 2
                        on: false
                        icon: Icons.g(0xf0379)
                        title: "Displays"
                        subtitle: Displays.outputs.length > 0 ? Displays.outputs.filter(o => o.active).length + " active" : "Resolution, refresh"
                        hasMore: true
                        onClicked: { Displays.refresh(); root.page = "display"; }
                        onMore: { Displays.refresh(); root.page = "display"; }
                    }
                    Toggle {
                        width: (mainPage.width - 10) / 2
                        on: Fluid.awake
                        icon: Icons.g(0xf0176)
                        title: "Keep awake"
                        subtitle: Fluid.awake ? "no dim, lock or sleep" : "off"
                        onClicked: Fluid.setAwake(!Fluid.awake)
                    }
                    Toggle {
                        width: (mainPage.width - 10) / 2
                        on: NightLight.on
                        icon: Icons.g(0xf0594)
                        title: "Night light"
                        subtitle: !NightLight.available ? "wlsunset not installed" : NightLight.on ? "on" : "off"
                        onClicked: NightLight.toggle()
                    }
                    Toggle {
                        width: (mainPage.width - 10) / 2
                        on: Fluid.recording
                        icon: Icons.g(0xf044a)
                        title: "Record screen"
                        subtitle: Fluid.recording ? "recording · tap to stop" : "whole screen · area: Super+Shift+R"
                        onClicked: { Fluid.closeAll(); Quickshell.execDetached([Quickshell.shellDir + "/scripts/fluid-record.sh"]); }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8
                    FSlider {
                        width: parent.width - 48
                        value: Audio.volume
                        icon: Icons.volume(Audio.percent, Audio.muted)
                        fillColor: Audio.muted ? Theme.urgent : Theme.audio
                        onMoved: v => Audio.setVolume(v)
                        onIconClicked: Audio.toggleMute()
                    }
                    // Sound page: output device, microphone, per-app volume
                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: soundMore.containsMouse ? Theme.surfaceHi : Theme.surface
                        Text { anchors.centerIn: parent; text: "›"; color: Theme.fg; font.pixelSize: 22 }
                        MouseArea { id: soundMore; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.page = "sound" }
                    }
                }

                // Night light strength: five steps, warmer to the right
                Row {
                    id: nightRow
                    visible: NightLight.on
                    width: parent.width
                    height: 40
                    spacing: 6
                    Glyph { width: 30; anchors.verticalCenter: parent.verticalCenter; text: Icons.g(0xf0594); color: Theme.fg }
                    Repeater {
                        model: NightLight.temps
                        Rectangle {
                            required property int index
                            readonly property bool chosen: index === NightLight.level
                            width: (nightRow.width - 30 - 5 * 6) / 5; height: 40; radius: 20
                            // from pale to the full clock colour = from barely to very warm
                            color: chosen ? Theme.clock : Qt.alpha(Theme.clock, 0.12 + index * 0.08)
                            border.width: nArea.containsMouse && !chosen ? 1 : 0
                            border.color: Theme.clock
                            Behavior on color { ColorAnimation { duration: Anim.fast } }
                            Text {
                                anchors.centerIn: parent
                                text: index + 1
                                color: parent.chosen ? Theme.onPill : Theme.fg
                                font.family: Theme.font; font.pixelSize: Theme.fontSize - 2; font.weight: Font.DemiBold
                            }
                            MouseArea { id: nArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: NightLight.setLevel(index) }
                        }
                    }
                }

                FSlider {
                    visible: Brightness.available
                    width: parent.width
                    value: Brightness.value
                    icon: Icons.sun
                    fillColor: Theme.backlight
                    onMoved: v => Brightness.set(v)
                }

                // Compact now-playing
                Rectangle {
                    visible: Media.active
                    width: parent.width
                    height: 64
                    radius: 16
                    color: Theme.surfaceHi
                    Row {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10
                        ClippingRectangle {
                            width: 48; height: 48; radius: 10
                            color: Theme.bg
                            Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                        }
                        Column {
                            width: parent.width - 48 - 3 * 36 - 30
                            anchors.verticalCenter: parent.verticalCenter
                            Text { width: parent.width; elide: Text.ElideRight; text: Media.title; color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2; font.weight: Font.DemiBold }
                            Text { width: parent.width; elide: Text.ElideRight; text: Media.artist; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
                        }
                        Repeater {
                            model: [
                                { i: Icons.prev, f: () => Media.previous() },
                                { i: Media.playing ? Icons.pause : Icons.play, f: () => Media.toggle() },
                                { i: Icons.next, f: () => Media.next() }
                            ]
                            Item {
                                required property var modelData
                                width: 36; height: 48
                                Glyph { anchors.centerIn: parent; text: parent.modelData.i }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData.f() }
                            }
                        }
                    }
                }

                // Notification history
                Item {
                    width: parent.width
                    height: 24
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Notifs.count > 0 ? `Notifications (${Notifs.count})` : "No notifications"
                        color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Notifs.count > 0
                        text: "Clear all"
                        color: clearAll.containsMouse ? Theme.fg : Theme.fgDim
                        font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                        MouseArea { id: clearAll; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearAll() }
                    }
                }

                ListView {
                    id: notifList
                    width: parent.width
                    height: Math.min(contentHeight, 300)
                    visible: count > 0
                    clip: true
                    spacing: 8
                    model: ScriptModel { values: Notifs.history.slice().reverse() }
                    boundsBehavior: Flickable.StopAtBounds
                    remove: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "x"; to: 420; duration: Anim.normal; easing.type: Easing.InCubic }
                            NumberAnimation { property: "opacity"; to: 0; duration: Anim.normal }
                        }
                    }
                    displaced: Transition { NumberAnimation { property: "y"; duration: Anim.normal; easing.type: Easing.OutCubic } }
                    delegate: NotificationCard {
                        required property var modelData
                        width: notifList.width
                        notification: modelData
                        onClose: Notifs.dismiss(modelData)
                    }
                }

                // Power row
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    Repeater {
                        model: [
                            // Sleep (hibernates after 12 h asleep or on low battery); locking is $mod+Shift+s
                            { i: Icons.moon, tip: "Sleep", cmd: [Quickshell.shellDir + "/scripts/fluid-sleep.sh"], confirm: false },
                            { i: Icons.g(0xf2f5), tip: "Log out", cmd: ["swaymsg", "exit"], confirm: true },
                            { i: Icons.g(0xf0709), tip: "Reboot", cmd: ["systemctl", "reboot"], confirm: true },
                            { i: Icons.power, tip: "Shut down", cmd: ["systemctl", "poweroff"], confirm: true }
                        ]
                        Rectangle {
                            id: pbtn
                            required property var modelData
                            property bool armed: false
                            width: 64; height: 44; radius: 14
                            color: armed ? Theme.urgent : (pArea.containsMouse ? Theme.surfaceHi : Theme.surface)
                            Behavior on color { ColorAnimation { duration: Anim.fast } }
                            Glyph { anchors.centerIn: parent; text: pbtn.armed ? "?" : pbtn.modelData.i }
                            Timer { id: disarm; interval: 2500; onTriggered: pbtn.armed = false }
                            MouseArea {
                                id: pArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                // Destructive actions need a second click within 2.5s
                                onClicked: {
                                    if (pbtn.modelData.confirm && !pbtn.armed) { pbtn.armed = true; disarm.restart(); return; }
                                    Fluid.closeAll();
                                    if (pbtn.modelData.cmd) Quickshell.execDetached(pbtn.modelData.cmd);
                                    else Fluid.lockRequested();
                                }
                            }
                        }
                    }
                }
            }

            // ================= Wi-Fi page =================
            Column {
                id: wifiPage
                width: viewport.width
                visible: root.sub === "wifi"
                spacing: 8

                PageHeader {
                    title: "Wi-Fi"
                    onBack: root.page = "main"
                    actionText: Network.wifiEnabled ? "Rescan" : ""
                    onAction: Network.scan()
                }

                Loader {
                    width: parent.width
                    active: root.page === "wifi"
                    sourceComponent: OrbitView {
                        width: wifiPage.width
                        readonly property var others: Network.networks.filter(n => !n.active).slice(0, 8)
                        Component.onCompleted: Network.scan()
                        busy: !Network.wifiEnabled ? false : Network.networks.length === 0
                        center: ({
                            title: !Network.wifiEnabled ? "Wi-Fi off" : (Network.connected ? Network.name : "Not connected"),
                            subtitle: Network.connected ? (Network.type === "ethernet" ? "Ethernet" : Network.signal + "%  ·  " + Network.ip) : "tap to turn " + (Network.wifiEnabled ? "off" : "on"),
                            icon: Network.type === "ethernet" ? Icons.ethernet : (Network.connected ? Icons.wifi : Icons.wifiOff),
                            active: Network.connected
                        })
                        items: others.map(n => ({ title: n.ssid, subtitle: n.signal + "%" + (n.secure ? " · " + Icons.lock : ""), icon: Icons.wifi, active: false }))
                        onItemClicked: i => Network.connect(others[i].ssid)
                        onCenterClicked: if (!Network.connected) Network.setWifi(!Network.wifiEnabled)
                    }
                }
            }

            // ================= Bluetooth page =================
            Column {
                id: btPage
                width: viewport.width
                visible: root.sub === "bt"
                spacing: 8

                PageHeader {
                    title: "Bluetooth"
                    onBack: { if (Bt.adapter) Bt.adapter.discovering = false; root.page = "main"; }
                    actionText: Bt.enabled ? (Bt.adapter && Bt.adapter.discovering ? "Stop scan" : "Scan") : ""
                    onAction: if (Bt.adapter) Bt.adapter.discovering = !Bt.adapter.discovering
                }

                Loader {
                    width: parent.width
                    active: root.page === "bt"
                    sourceComponent: OrbitView {
                        width: btPage.width
                        readonly property var hubDevice: Bt.connected.length > 0 ? Bt.connected[0] : null
                        // connected first, then paired, then newly discovered (named ones only)
                        readonly property var others: Bt.devices
                            .filter(d => d !== hubDevice && (d.paired || d.connected || d.name))
                            .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired))
                            .slice(0, 8)
                        busy: !!(Bt.adapter && Bt.adapter.discovering)
                        center: hubDevice ? ({
                            title: hubDevice.name,
                            subtitle: "Connected" + (hubDevice.batteryAvailable ? " · " + Math.round(hubDevice.battery * 100) + "%" : ""),
                            icon: Icons.btConnected, active: true
                        }) : ({ title: Bt.enabled ? "Bluetooth" : "Bluetooth off", subtitle: Bt.enabled ? "no device connected" : "tap to turn on",
                                icon: Bt.enabled ? Icons.btOn : Icons.btOff, active: false })
                        items: others.map(d => ({
                            title: d.name || d.address,
                            subtitle: d.connected ? "connected" : d.paired ? "paired" : "tap to pair",
                            icon: Icons.btOn, active: d.connected
                        }))
                        onItemClicked: i => {
                            const d = others[i];
                            if (!d.paired && !d.connected) { d.trusted = true; d.pair(); }
                            else Bt.toggleDevice(d);
                        }
                        onCenterClicked: hubDevice ? hubDevice.disconnect() : Bt.setEnabled(!Bt.enabled)
                    }
                }

                // AirPods (through scripts/fluid-pods.py): battery per pod + noise mode
                Column {
                    visible: Pods.connected
                    width: parent.width
                    spacing: 10

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 22
                        Repeater {
                            model: (Pods.isMax ? ["headset"] : ["left", "right", "case"]).filter(p => Pods.level(p) >= 0)
                            Column {
                                required property string modelData
                                spacing: 4
                                Ring {
                                    value: Pods.level(modelData) / 100
                                    text: Pods.level(modelData) + "%"
                                    color: Pods.charging(modelData) ? Theme.cpu : Pods.level(modelData) <= 20 ? Theme.urgent : Theme.clock
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: ({ left: "Left", right: "Right", case: "Case", headset: "Battery" })[modelData] + (Pods.charging(modelData) ? " " + Icons.bolt : "")
                                    color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4
                                }
                            }
                        }
                    }

                    // Noise control, segmented
                    Segmented {
                        visible: Pods.anc !== ""
                        width: parent.width
                        options: [{ value: "off", label: "Off" }, { value: "transparency", label: "Transparency" },
                                  { value: "adaptive", label: "Adaptive" }, { value: "on", label: "Noise cancel" }]
                        current: Pods.anc
                        onPicked: v => Pods.setAnc(v)
                    }

                    Toggle {
                        width: parent.width
                        on: Pods.ca
                        icon: Icons.g(0xf0130)
                        title: "Conversation Awareness"
                        subtitle: "lowers media when you start talking"
                        onClicked: Pods.setCa(!Pods.ca)
                    }
                }
            }

            // ================= Displays page =================
            Column {
                id: displayPage
                width: viewport.width
                visible: root.sub === "display"
                spacing: 12

                PageHeader { title: "Displays"; onBack: { Displays.revert(); root.page = "main"; } }

                // ---- Arrangement: drag screens, they snap edge to edge ----------
                Rectangle {
                    id: stage
                    width: parent.width; height: 170; radius: 14
                    color: Theme.surface
                    clip: true

                    readonly property var act: Displays.outputs.filter(o => o.active)
                    // layout size of an output = pixels / scale
                    function lw(o) { return o.width / o.scale; }
                    function lh(o) { return o.height / o.scale; }
                    readonly property var bounds: {
                        if (!act.length) return { x: 0, y: 0, w: 1, h: 1 };
                        const x0 = Math.min(...act.map(o => o.x)), y0 = Math.min(...act.map(o => o.y));
                        const x1 = Math.max(...act.map(o => o.x + lw(o))), y1 = Math.max(...act.map(o => o.y + lh(o)));
                        return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 };
                    }
                    readonly property real k: Math.min((width - 40) / (bounds.w * 1.3), (height - 30) / (bounds.h * 1.3))
                    property var moved: ({})                 // name -> { x, y } in layout pixels
                    readonly property bool dirty: Object.keys(moved).length > 0
                    onActChanged: moved = ({})

                    function pos(o) { return moved[o.name] || { x: o.x, y: o.y }; }
                    function snap(o, nx, ny) {
                        const w = lw(o), h = lh(o), t = 60 / Math.max(0.05, k) * 0.15 + 40;
                        let bx = nx, by = ny, dx = t, dy = t;
                        for (const p of act) {
                            if (p.name === o.name) continue;
                            const q = pos(p), pw = lw(p), ph = lh(p);
                            for (const cx of [q.x - w, q.x + pw, q.x, q.x + pw - w]) if (Math.abs(cx - nx) < dx) { dx = Math.abs(cx - nx); bx = cx; }
                            for (const cy of [q.y, q.y + ph - h, q.y - h, q.y + ph]) if (Math.abs(cy - ny) < dy) { dy = Math.abs(cy - ny); by = cy; }
                        }
                        const m = Object.assign({}, moved);
                        m[o.name] = { x: Math.round(bx), y: Math.round(by) };
                        moved = m;
                    }

                    Repeater {
                        model: stage.act
                        Rectangle {
                            id: mon
                            required property var modelData
                            readonly property var p: stage.pos(modelData)
                            width: stage.lw(modelData) * stage.k
                            height: stage.lh(modelData) * stage.k
                            // laid out from the model; while dragging, the finger offset is added on top
                            readonly property real baseX: 20 + (stage.width - 40 - stage.bounds.w * stage.k) / 2 + (p.x - stage.bounds.x) * stage.k
                            readonly property real baseY: 15 + (stage.height - 30 - stage.bounds.h * stage.k) / 2 + (p.y - stage.bounds.y) * stage.k
                            property point offset: Qt.point(0, 0)
                            x: baseX + offset.x
                            y: baseY + offset.y
                            z: drag.active ? 2 : 1
                            Behavior on x { enabled: !drag.active; NumberAnimation { duration: Anim.normal; easing.type: Easing.OutBack } }
                            Behavior on y { enabled: !drag.active; NumberAnimation { duration: Anim.normal; easing.type: Easing.OutBack } }
                            radius: 8
                            color: drag.active ? Theme.clock : Theme.surfaceHi
                            border.width: 2
                            border.color: Theme.clock
                            Column {
                                anchors.centerIn: parent
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: mon.modelData.name; color: drag.active ? Theme.onPill : Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4; font.weight: Font.DemiBold }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: mon.modelData.width + "×" + mon.modelData.height; color: drag.active ? Theme.onPill : Theme.fgDim; font.family: Theme.font; font.pixelSize: 9 }
                            }
                            DragHandler {
                                id: drag
                                target: null
                                onActiveTranslationChanged: if (active) mon.offset = Qt.point(activeTranslation.x, activeTranslation.y)
                                onActiveChanged: if (!active) {
                                    const nx = mon.p.x + mon.offset.x / stage.k, ny = mon.p.y + mon.offset.y / stage.k;
                                    mon.offset = Qt.point(0, 0);
                                    stage.snap(mon.modelData, nx, ny);
                                }
                            }
                        }
                    }

                    Text {
                        anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 8
                        visible: !stage.dirty
                        text: "Drag screens to arrange them"
                        color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 5
                    }
                    Row {
                        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 8
                        spacing: 6
                        visible: stage.dirty
                        Repeater {
                            model: [{ t: "Apply", main: true }, { t: "Reset", main: false }]
                            Chip {
                                required property var modelData
                                text: modelData.t
                                on: modelData.main
                                size: Theme.fontSize - 4
                                onClicked: { if (modelData.main) Displays.arrange(stage.moved); stage.moved = ({}); }
                            }
                        }
                    }
                }

                property int sel: 0
                readonly property var out: Displays.outputs[Math.min(sel, Displays.outputs.length - 1)] || null
                readonly property var resolutions: {
                    if (!out) return [];
                    const seen = {};
                    return out.modes.filter(m => { const k = m.w + "x" + m.h; if (seen[k]) return false; seen[k] = true; return true; })
                                    .sort((a, b) => b.w * b.h - a.w * a.h).slice(0, 8);
                }
                property int pickW: out ? out.width : 0
                property int pickH: out ? out.height : 0
                property int pickR: out ? out.refresh : 0
                property real pickScale: out ? out.scale : 1
                onOutChanged: if (out) { pickW = out.width; pickH = out.height; pickR = out.refresh; pickScale = out.scale; }
                readonly property var rates: out ? out.modes.filter(m => m.w === pickW && m.h === pickH).map(m => m.r).sort((a, b) => a - b) : []

                // Output tabs
                Flow {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: Displays.outputs
                        Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool on: displayPage.sel === index
                            height: 44; radius: 14
                            width: oText.implicitWidth + 28
                            color: on ? Theme.clock : Theme.surface
                            Column {
                                id: oText
                                anchors.centerIn: parent
                                Text { text: modelData.name; color: parent.parent.on ? Theme.onPill : Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2; font.weight: Font.DemiBold }
                                Text { text: modelData.width + "×" + modelData.height + " @ " + Math.round(modelData.refresh / 1000) + " Hz"; color: parent.parent.on ? Theme.onPill : Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 5 }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: displayPage.sel = parent.index }
                        }
                    }
                }

                Text { text: "Resolution"; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
                Grid {
                    columns: 2
                    columnSpacing: 6; rowSpacing: 6
                    width: parent.width
                    Repeater {
                        model: displayPage.resolutions
                        Rectangle {
                            required property var modelData
                            readonly property bool on: displayPage.pickW === modelData.w && displayPage.pickH === modelData.h
                            readonly property string tag: ({ "3840x2160": "4K", "2560x1440": "QHD", "2560x1600": "WQXGA", "1920x1200": "WUXGA",
                                                             "1920x1080": "FHD", "1600x900": "HD+", "1280x720": "HD" })[modelData.w + "x" + modelData.h] || ""
                            width: (displayPage.width - 6) / 2; height: 34; radius: 12
                            color: on ? Theme.clock : (rArea.containsMouse ? Theme.surfaceHi : Theme.surface)
                            Behavior on color { ColorAnimation { duration: Anim.fast } }
                            Text { anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: parent.tag; color: parent.on ? Theme.onPill : Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4; font.weight: Font.DemiBold }
                            Text { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.w + "×" + modelData.h; color: parent.on ? Theme.onPill : Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
                            MouseArea {
                                id: rArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    displayPage.pickW = modelData.w; displayPage.pickH = modelData.h;
                                    const r = displayPage.rates;
                                    displayPage.pickR = r.length ? r[r.length - 1] : displayPage.pickR;
                                }
                            }
                        }
                    }
                }

                TweakSlider {
                    width: parent.width
                    visible: displayPage.rates.length > 1
                    label: "Refresh rate"
                    from: 0; to: Math.max(1, displayPage.rates.length - 1); step: 1; decimals: 0
                    defaultValue: 0
                    value: Math.max(0, displayPage.rates.indexOf(displayPage.pickR))
                    valueText: Math.round(displayPage.pickR / 1000) + " Hz"
                    onMoved: v => displayPage.pickR = displayPage.rates[Math.round(v)]
                }

                Row {
                    spacing: 6
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Scale"; width: 60; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
                    Repeater {
                        model: [1, 1.25, 1.5, 2]
                        Rectangle {
                            required property real modelData
                            readonly property bool on: Math.abs(displayPage.pickScale - modelData) < 0.01
                            width: 56; height: 30; radius: 10
                            color: on ? Theme.clock : Theme.surface
                            Text { anchors.centerIn: parent; text: parent.modelData + "×"; color: parent.on ? Theme.onPill : Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: displayPage.pickScale = parent.modelData }
                        }
                    }
                }

                // Apply, then confirm within 15 s or it reverts
                Rectangle {
                    width: parent.width; height: 44; radius: 14
                    readonly property bool confirming: Displays.pendingRevert !== null
                    color: confirming ? Theme.surfaceHi : Theme.clock
                    Behavior on color { ColorAnimation { duration: Anim.fast } }
                    Text {
                        visible: !parent.confirming
                        anchors.centerIn: parent
                        text: "Apply"
                        color: Theme.onPill; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; font.weight: Font.DemiBold
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !parent.confirming && displayPage.out !== null
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Displays.apply(displayPage.out, displayPage.pickW, displayPage.pickH, displayPage.pickR, displayPage.pickScale)
                    }
                    Row {
                        visible: parent.confirming
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 6
                        Text {
                            width: parent.width - 2 * 90 - 12
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: 8
                            text: "Keep? Reverting in " + Displays.countdown + " s"
                            color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                        }
                        Repeater {
                            model: [{ t: "Keep", f: () => Displays.keep(), main: true }, { t: "Revert", f: () => Displays.revert(), main: false }]
                            Rectangle {
                                required property var modelData
                                width: 90; height: parent.height; radius: 10
                                color: modelData.main ? Theme.clock : Theme.surface
                                Text { anchors.centerIn: parent; text: parent.modelData.t; color: parent.modelData.main ? Theme.onPill : Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData.f() }
                            }
                        }
                    }
                }

                // ---- Profiles: re-applied automatically when the same screens connect ----
                Text { text: "Profiles  ·  applied automatically on hotplug"; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
                Flow {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: Displays.profiles
                        Rectangle {
                            required property var modelData
                            height: 30; radius: 15
                            width: pn.implicitWidth + 46
                            color: Theme.surface
                            Text { id: pn; x: 14; anchors.verticalCenter: parent.verticalCenter; text: parent.modelData.name + "  (" + parent.modelData.outputs.filter(o => o.enabled).length + ")"; color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
                            Text {
                                anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                                text: "×"; color: delArea.containsMouse ? Theme.urgent : Theme.fgDim; font.pixelSize: 16
                                MouseArea { id: delArea; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Displays.deleteProfile(parent.parent.modelData.name) }
                            }
                        }
                    }
                }
                Row {
                    width: parent.width
                    spacing: 6
                    Rectangle {
                        width: parent.width - saveBtn.width - 6; height: 36; radius: 12
                        color: Theme.surface
                        TextInput {
                            id: profileName
                            anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                            Keys.onReturnPressed: { Displays.saveProfile(text); text = ""; }
                            Text { visible: !profileName.text; anchors.verticalCenter: parent.verticalCenter; text: "Name this setup (e.g. Desk, Docked)"; color: Theme.fgDim; font: profileName.font }
                        }
                    }
                    Rectangle {
                        id: saveBtn
                        width: 110; height: 36; radius: 12
                        color: Theme.clock
                        Text { anchors.centerIn: parent; text: "Save current"; color: Theme.onPill; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Displays.saveProfile(profileName.text); profileName.text = ""; } }
                    }
                }
            }

            // ================= Sound page =================
            // Output device, microphone and per-app volume (services/Audio.qml)
            Column {
                id: soundPage
                width: viewport.width
                visible: root.sub === "sound"
                spacing: 8

                PageHeader { title: "Sound"; onBack: root.page = "main" }

                FSlider {
                    width: parent.width
                    value: Audio.volume
                    icon: Icons.volume(Audio.percent, Audio.muted)
                    fillColor: Audio.muted ? Theme.urgent : Theme.audio
                    onMoved: v => Audio.setVolume(v)
                    onIconClicked: Audio.toggleMute()
                }

                SectionLabel { text: "Output" }
                Repeater {
                    model: Audio.outputs
                    DeviceRow {
                        required property var modelData
                        title: Audio.label(modelData)
                        selected: modelData === Audio.sink
                        onClicked: Audio.setOutput(modelData)
                    }
                }

                SectionLabel { text: "Microphone"; visible: Audio.inputs.length > 0 }
                Repeater {
                    model: Audio.inputs
                    DeviceRow {
                        required property var modelData
                        title: Audio.label(modelData)
                        selected: modelData === Audio.source
                        onClicked: Audio.setInput(modelData)
                    }
                }

                SectionLabel { text: Audio.streams.length > 0 ? "Apps" : "No app is playing sound" }
                Repeater {
                    model: Audio.streams
                    Column {
                        required property var modelData
                        width: soundPage.width
                        spacing: 4
                        Text {
                            x: 4
                            width: parent.width - 8; elide: Text.ElideRight
                            text: Audio.appName(parent.modelData)
                            color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                        }
                        FSlider {
                            width: parent.width
                            implicitHeight: 32
                            value: parent.modelData.audio ? parent.modelData.audio.volume : 0
                            icon: Icons.volume(Math.round(value * 100), parent.modelData.audio && parent.modelData.audio.muted)
                            fillColor: parent.modelData.audio && parent.modelData.audio.muted ? Theme.urgent : Theme.audio
                            onMoved: v => Audio.setStreamVolume(parent.modelData, v)
                            onIconClicked: if (parent.modelData.audio) parent.modelData.audio.muted = !parent.modelData.audio.muted
                        }
                    }
                }
            }
        }
    }

    component SectionLabel: Text {
        x: 4
        topPadding: 6
        color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
    }

    component PageHeader: Item {
        id: ph
        property string title
        property string actionText: ""
        signal back()
        signal action()
        width: parent.width
        height: 36
        Rectangle {
            id: backBtn
            width: 36; height: 36; radius: 18
            color: backArea.containsMouse ? Theme.surfaceHi : "transparent"
            Text { anchors.centerIn: parent; text: "‹"; color: Theme.fg; font.pixelSize: 24 }
            MouseArea { id: backArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ph.back() }
        }
        Text {
            anchors.left: backBtn.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: ph.title
            color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize + 1; font.weight: Font.DemiBold
        }
        Chip {
            visible: ph.actionText.length > 0
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: ph.actionText
            onClicked: ph.action()
        }
    }
}
