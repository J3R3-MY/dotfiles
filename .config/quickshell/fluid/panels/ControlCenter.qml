import QtQuick
import Quickshell
import Quickshell.Widgets
import "../common"
import "../services"

// macOS-style control center. Opens by hovering the top-right corner, clicking
// the bluetooth/audio/backlight/network pills, or $mod+i.
// Pages (main / wifi / bluetooth) slide sideways; the panel height follows
// the page so the shape morphs instead of jumping.
Item {
    id: root

    required property string screenName
    readonly property bool open: Fluid.ccOpen && Fluid.ccScreen === screenName
    property string page: "main"
    onOpenChanged: if (!open) page = "main"

    width: 400
    height: (page === "main" ? mainPage.implicitHeight : page === "wifi" ? wifiPage.implicitHeight : btPage.implicitHeight) + 32
    Behavior on height { NumberAnimation { duration: Anim.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } }

    // Grow out of the top-right corner
    transformOrigin: Item.TopRight
    scale: open ? 1 : 0.85
    opacity: open ? 1 : 0
    visible: opacity > 0
    Behavior on scale { NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.spring } }
    Behavior on opacity { NumberAnimation { duration: Anim.fast } }

    Keys.onEscapePressed: page === "main" ? Fluid.closeAll() : (page = "main")
    onVisibleChanged: if (visible) forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        radius: Theme.panelRadius
        color: Theme.bg
        border.width: 2
        border.color: Theme.border
    }

    Item {
        id: viewport
        anchors.fill: parent
        anchors.margins: 16
        clip: true

        Row {
            id: pages
            x: root.page === "main" ? 0 : -(viewport.width + 32)
            spacing: 32
            Behavior on x { NumberAnimation { duration: Anim.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } }

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
                }

                FSlider {
                    width: parent.width
                    value: Audio.volume
                    icon: Icons.volume(Audio.percent, Audio.muted)
                    fillColor: Audio.muted ? Theme.urgent : Theme.audio
                    onMoved: v => Audio.setVolume(v)
                    onIconClicked: Audio.toggleMute()
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
                            { i: Icons.lock, tip: "Lock", cmd: ["swaylock", "-f"], confirm: false },
                            { i: Icons.moon, tip: "Suspend", cmd: ["systemctl", "suspend"], confirm: false },
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
                                    Quickshell.execDetached(pbtn.modelData.cmd);
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
                spacing: 8

                PageHeader { title: "Wi-Fi"; onBack: root.page = "main"; busy: false }

                Repeater {
                    model: Network.networks.slice(0, 12)
                    ListRowItem {
                        required property var modelData
                        width: wifiPage.width
                        icon: Icons.wifi
                        title: modelData.ssid
                        subtitle: (modelData.active ? "Connected · " : "") + modelData.signal + "%" + (modelData.secure ? " · secured" : "")
                        highlighted: modelData.active
                        onClicked: if (!modelData.active) Network.connect(modelData.ssid)
                    }
                }
                Text {
                    visible: Network.networks.length === 0
                    text: Network.wifiEnabled ? "Scanning…" : "Wi-Fi is off"
                    color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                }
            }

            // ================= Bluetooth page =================
            Column {
                id: btPage
                width: viewport.width
                spacing: 8

                PageHeader { title: "Bluetooth"; onBack: root.page = "main" }

                Repeater {
                    model: Bt.paired
                    ListRowItem {
                        required property var modelData
                        width: btPage.width
                        icon: modelData.connected ? Icons.btConnected : Icons.btOn
                        title: modelData.name || modelData.address
                        subtitle: modelData.connected
                            ? "Connected" + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "%" : "")
                            : "Not connected"
                        highlighted: modelData.connected
                        onClicked: Bt.toggleDevice(modelData)
                    }
                }
                Text {
                    visible: Bt.paired.length === 0
                    text: "No paired devices — pair new ones with blueberry (right-click the bar pill)"
                    wrapMode: Text.Wrap
                    width: parent.width
                    color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                }
            }
        }
    }

    component PageHeader: Item {
        id: ph
        property string title
        property bool busy: false
        signal back()
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
    }

    component ListRowItem: Rectangle {
        id: lr
        property string icon
        property string title
        property string subtitle
        property bool highlighted: false
        signal clicked()
        height: 52
        radius: 14
        color: highlighted ? Theme.accent : (lrArea.containsMouse ? Theme.surfaceHi : Theme.surface)
        Behavior on color { ColorAnimation { duration: Anim.fast } }
        Row {
            anchors.fill: parent
            anchors.leftMargin: 14
            spacing: 12
            Glyph { anchors.verticalCenter: parent.verticalCenter; text: lr.icon; color: lr.highlighted ? Theme.onPill : Theme.fg }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: lr.width - 60
                Text { width: parent.width; elide: Text.ElideRight; text: lr.title; color: lr.highlighted ? Theme.onPill : Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
                Text { width: parent.width; elide: Text.ElideRight; text: lr.subtitle; color: lr.highlighted ? Theme.onPill : Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
            }
        }
        MouseArea { id: lrArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: lr.clicked() }
    }
}
