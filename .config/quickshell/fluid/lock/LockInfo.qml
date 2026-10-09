import QtQuick
import Quickshell
import Quickshell.Widgets
import "../common"
import "../services"

// Info: clock plus cards for weather, what's playing and the machine.
Item {
    id: root
    required property var lock

    SystemClock { id: clock; precision: SystemClock.Minutes }

    component Card: Rectangle {
        width: 260; height: 130; radius: 22
        color: Qt.rgba(0, 0, 0, 0.35)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)
    }

    LockBackground { anchors.fill: parent; blur: 0.9; dim: 0.3 }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.14
        spacing: 4
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: "white"; font.family: "JetBrains Mono"; font.pixelSize: 110; font.weight: Font.Bold
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: Qt.rgba(1, 1, 1, 0.8); font.family: Theme.font; font.pixelSize: 20
        }
    }

    Row {
        id: cards
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.45
        spacing: 18

        Card {
            Row {
                anchors.centerIn: parent
                spacing: 16
                Glyph { text: Weather.icon; size: 44; color: "white"; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: Weather.ready ? Math.round(Weather.temp) + "°" : "—"; color: "white"; font.family: Theme.font; font.pixelSize: 36; font.weight: Font.Bold }
                    Text { text: Weather.summary + (Weather.city ? " · " + Weather.city : ""); color: Qt.rgba(1, 1, 1, 0.75); font.family: Theme.font; font.pixelSize: 13 }
                }
            }
        }

        Card {
            Row {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14
                ClippingRectangle {
                    width: 98; height: 98; radius: 14
                    color: Qt.rgba(1, 1, 1, 0.1)
                    Glyph { anchors.centerIn: parent; text: Icons.music; size: 30; color: "white"; visible: !Media.art }
                    Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                }
                Column {
                    width: parent.width - 112
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Text { width: parent.width; elide: Text.ElideRight; text: Media.active ? Media.title : "Nothing playing"; color: "white"; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.DemiBold }
                    Text { width: parent.width; elide: Text.ElideRight; text: Media.artist; color: Qt.rgba(1, 1, 1, 0.75); font.family: Theme.font; font.pixelSize: 12 }
                    Text { visible: Media.active; text: Media.playing ? Icons.pause + "  playing" : Icons.play + "  paused"; color: Qt.rgba(1, 1, 1, 0.6); font.family: Theme.font; font.pixelSize: 12 }
                }
            }
        }

        Card {
            Column {
                anchors.centerIn: parent
                spacing: 8
                Text { text: (Battery.available ? Icons.battery(Battery.percent, Battery.charging) + "  " + Battery.percent + "%" : Icons.bolt + "  AC") + (Battery.timeLeft ? "  · " + Battery.timeLeft : ""); color: "white"; font.family: Theme.font; font.pixelSize: 15 }
                Text { text: Icons.memory + "  " + SysStats.memory + "% memory"; color: "white"; font.family: Theme.font; font.pixelSize: 15 }
                Text { text: Icons.clock + "  up " + Battery.uptime; color: "white"; font.family: Theme.font; font.pixelSize: 15 }
            }
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.72
        spacing: 14
        opacity: root.lock.authMode ? 1 : 0.0
        Behavior on opacity { NumberAnimation { duration: Anim.normal } }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12
            Avatar { size: 40; user: root.lock.user; anchors.verticalCenter: parent.verticalCenter }
            Text { text: root.lock.user; color: "white"; font.family: Theme.font; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter }
        }
        PasswordPill { anchors.horizontalCenter: parent.horizontalCenter; lock: root.lock }
    }
}
