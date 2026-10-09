import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../common"
import "../services"

// Battery / power panel, opened from the battery pill.
// Battery ring, uptime, brightness + volume, session buttons and power
// profiles (power-profiles-daemon).
Item {
    id: root

    required property string screenName
    readonly property bool open: Fluid.powerOpen && Fluid.powerScreen === screenName

    width: 340
    height: col.implicitHeight + 32

    transformOrigin: Item.TopRight
    scale: open ? 1 : 0.85
    opacity: open ? 1 : 0
    visible: opacity > 0
    Behavior on scale { NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.spring } }
    Behavior on opacity { NumberAnimation { duration: Anim.fast } }

    Keys.onEscapePressed: Fluid.closeAll()
    onVisibleChanged: if (visible) forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        radius: Theme.panelRadius
        color: Theme.bg
        border.width: 2
        border.color: Theme.border
    }

    Column {
        id: col
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        // Uptime + lock style
        Row {
            spacing: 8
            Rectangle {
                height: 28; radius: 10
                width: lsText.implicitWidth + 20
                color: lsArea.containsMouse ? Theme.surfaceHi : Theme.surface
                Text { id: lsText; anchors.centerIn: parent; text: Icons.lock + "  Lock style"; color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
                MouseArea { id: lsArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Fluid.openIsland("lockstyle", root.screenName) }
            }
            Rectangle {
                height: 28; radius: 10
                width: up.implicitWidth + 20
                color: Theme.surfaceHi
                Text { id: up; anchors.centerIn: parent; text: "up " + Battery.uptime; color: Theme.fg; font.family: "JetBrains Mono"; font.pixelSize: Theme.fontSize - 4 }
            }
        }

        // Battery ring
        Item {
            width: parent.width
            height: 190

            Canvas {
                id: ring
                anchors.centerIn: parent
                width: 180; height: 180
                property real shown: Battery.available ? Battery.percent / 100 : 1
                Behavior on shown { NumberAnimation { duration: 900; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } }
                onShownChanged: requestPaint()
                Connections { target: Theme; function onClockChanged() { ring.requestPaint(); } }
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const c = width / 2, r = c - 10;
                    ctx.lineWidth = 12;
                    ctx.lineCap = "round";
                    ctx.strokeStyle = String(Theme.surfaceHi);
                    ctx.beginPath(); ctx.arc(c, c, r, 0, 2 * Math.PI); ctx.stroke();
                    ctx.strokeStyle = String(Battery.critical ? Theme.urgent : Theme.clock);
                    ctx.beginPath(); ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + shown * 2 * Math.PI); ctx.stroke();
                }

                // Soft pulse while charging
                Rectangle {
                    anchors.centerIn: parent
                    width: 140; height: 140; radius: 70
                    color: Theme.clock
                    opacity: 0
                    SequentialAnimation on opacity {
                        running: Battery.charging
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.12; duration: 1200; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0; duration: 1200; easing.type: Easing.InOutSine }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Battery.available ? Icons.battery(Battery.percent, Battery.charging) + " " + Battery.percent + "%" : Icons.bolt + " AC"
                        color: Theme.fg; font.family: "JetBrains Mono"; font.pixelSize: 30; font.weight: Font.Bold
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: !Battery.available ? "no battery"
                            : (Battery.charging ? "charging" : "on battery") + (Battery.timeLeft ? " · " + Battery.timeLeft : "")
                        color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4
                    }
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
        FSlider {
            width: parent.width
            value: Audio.volume
            icon: Icons.volume(Audio.percent, Audio.muted)
            fillColor: Audio.muted ? Theme.urgent : Theme.audio
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
        }

        // Session buttons; reboot / power off need a second click
        Row {
            width: parent.width
            spacing: 8
            Repeater {
                model: [
                    { i: Icons.lock, cmd: null, confirm: false },
                    { i: Icons.moon, cmd: ["systemctl", "suspend"], confirm: false },
                    { i: Icons.g(0xf0709), cmd: ["systemctl", "reboot"], confirm: true },
                    { i: Icons.power, cmd: ["systemctl", "poweroff"], confirm: true }
                ]
                Rectangle {
                    id: sbtn
                    required property var modelData
                    property bool armed: false
                    width: (col.width - 24) / 4; height: 46; radius: 14
                    color: armed ? Theme.urgent : (sArea.containsMouse ? Theme.surfaceHi : Theme.surface)
                    Behavior on color { ColorAnimation { duration: Anim.fast } }
                    Glyph { anchors.centerIn: parent; text: sbtn.armed ? "?" : sbtn.modelData.i }
                    Timer { id: disarm; interval: 2500; onTriggered: sbtn.armed = false }
                    MouseArea {
                        id: sArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (sbtn.modelData.confirm && !sbtn.armed) { sbtn.armed = true; disarm.restart(); return; }
                            Fluid.closeAll();
                            if (sbtn.modelData.cmd) Quickshell.execDetached(sbtn.modelData.cmd);
                            else Fluid.lockRequested();
                        }
                    }
                }
            }
        }

        // Power profiles
        Rectangle {
            id: prof
            width: parent.width; height: 40; radius: 14
            color: Theme.surface
            readonly property var items: [
                { p: PowerProfile.Performance, t: Icons.g(0xf0e7) + "  Perform", show: Battery.hasPerformance },
                { p: PowerProfile.Balanced, t: Icons.g(0xf24e) + "  Balance", show: true },
                { p: PowerProfile.PowerSaver, t: Icons.g(0xf06c) + "  Saver", show: true }
            ].filter(x => x.show)
            readonly property int sel: Math.max(0, items.findIndex(x => x.p === Battery.profile))

            Rectangle {
                y: 4; height: parent.height - 8; radius: 11
                width: (prof.width - 8) / prof.items.length
                x: 4 + prof.sel * width
                color: Theme.clock
                Behavior on x { NumberAnimation { duration: Anim.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.spring } }
            }
            Row {
                anchors.fill: parent
                anchors.margins: 4
                Repeater {
                    model: prof.items
                    Item {
                        required property var modelData
                        required property int index
                        width: (prof.width - 8) / prof.items.length; height: parent.height
                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.t
                            color: prof.sel === parent.index ? Theme.onPill : Theme.fg
                            font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Battery.setProfile(parent.modelData.p) }
                    }
                }
            }
        }
    }
}
