import QtQuick
import Quickshell
import Quickshell.Wayland
import "../common"
import "../services"

// One bar per output. Same layout as the old waybar:
//   left:   sway/workspaces, sway/mode
//   center: clock (drawn by the island in Overlay.qml, sitting on top of this bar)
//   right:  bluetooth, pulseaudio, backlight, cpu, memory, network, battery
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "fluid-bar"
    WlrLayershell.layer: WlrLayer.Top

    readonly property string screenName: modelData.name

    // Only the module rows take input; the centre stays click-through so the
    // island (a separate overlay window) receives clicks regardless of stacking.
    mask: Region {
        item: leftRow
        Region { item: rightRow }
    }

    Row {
        id: leftRow
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Workspaces { screenName: bar.screenName }

        // sway/mode: pops in when you enter e.g. resize mode
        Pill {
            id: modePill
            visible: opacity > 0
            opacity: Sway.mode.length > 0 ? 1 : 0
            scale: Sway.mode.length > 0 ? 1 : 0.7
            color: Theme.mode
            textColor: Theme.fg
            label: Sway.mode
            Behavior on opacity { NumberAnimation { duration: Anim.normal } }
            Behavior on scale { NumberAnimation { duration: Anim.normal; easing.type: Easing.OutBack } }
        }
    }

    Row {
        id: rightRow
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        layoutDirection: Qt.LeftToRight

        // Every pill animates its width, so the Row re-flows smoothly too
        move: Transition {
            NumberAnimation { properties: "x"; duration: Anim.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized }
        }

        Pill {
            visible: Bt.available
            color: Bt.enabled ? Theme.bluetooth : Theme.urgent
            textColor: Bt.enabled ? Theme.onPill : Theme.fg
            icon: !Bt.enabled ? Icons.btOff : (Bt.connected.length > 0 ? Icons.btConnected : Icons.btOn)
            label: Bt.label
            detail: Bt.connected.length > 1 ? `+${Bt.connected.length - 1}` : ""
            onClicked: m => m.button === Qt.RightButton
                ? Quickshell.execDetached(["blueberry"])
                : Fluid.toggleControlCenter(bar.screenName)
        }

        Pill {
            color: Audio.muted ? Theme.urgent : Theme.audio
            textColor: Audio.muted ? Theme.fg : Theme.onPill
            label: Audio.muted ? "" : Audio.percent + "%"
            icon: Icons.volume(Audio.percent, Audio.muted) + (Audio.micMuted ? "  " + Icons.micOff : "")
            detail: Audio.sinkName
            onScrolled: d => Audio.setVolume(Audio.volume + d * 0.05)
            onClicked: m => {
                if (m.button === Qt.RightButton) Quickshell.execDetached(["pavucontrol"]);   // old on-click
                else if (m.button === Qt.MiddleButton) Audio.toggleMute();
                else Fluid.toggleControlCenter(bar.screenName);
            }
        }

        Pill {
            visible: Brightness.available
            color: Theme.backlight
            label: Brightness.percent + "%"
            icon: Brightness.percent > 50 ? Icons.sun : Icons.moon
            onScrolled: d => Brightness.set(Brightness.value + d * 0.05)
            onClicked: Fluid.toggleControlCenter(bar.screenName)
        }

        Pill {
            color: Theme.cpu
            label: SysStats.cpu + "%"
            icon: Icons.cpu
            onClicked: Quickshell.execDetached(["wezterm", "start", "--", "htop"])
        }

        Pill {
            color: Theme.memory
            label: SysStats.memory + "%"
            icon: Icons.memory
            detail: SysStats.memUsedGiB.toFixed(1) + " / " + SysStats.memTotalGiB.toFixed(1) + " GiB"
            onClicked: Quickshell.execDetached(["wezterm", "start", "--", "htop"])
        }

        Pill {
            color: Network.connected ? Theme.network : Theme.urgent
            textColor: Network.connected ? Theme.onPill : Theme.fg
            icon: Network.type === "ethernet" ? Icons.ethernet : (Network.connected ? Icons.wifi : Icons.wifiOff)
            label: Network.connected ? Network.name : "Disconnected"
            detail: Network.ip
            onClicked: Fluid.toggleControlCenter(bar.screenName)
        }

        Pill {
            visible: Battery.available
            color: Battery.charging ? Theme.accent : Theme.battery
            alert: Battery.critical
            label: Battery.percent + "%"
            icon: Icons.battery(Battery.percent, Battery.charging)
            detail: Battery.timeLeft
            onClicked: Fluid.togglePower(bar.screenName)
        }
    }
}
