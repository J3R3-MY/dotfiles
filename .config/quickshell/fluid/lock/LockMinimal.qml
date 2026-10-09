import QtQuick
import Quickshell
import "../common"

// Minimal: plain wallpaper, small clock and the password field bottom-left.
Item {
    id: root
    required property var lock

    SystemClock { id: clock; precision: SystemClock.Minutes }

    LockBackground { anchors.fill: parent; blur: 0; dim: root.lock.authMode ? 0.3 : 0.15 }

    // soft gradient so the text stays readable on bright wallpapers
    Rectangle {
        anchors.left: parent.left; anchors.bottom: parent.bottom
        width: parent.width * 0.6; height: parent.height * 0.45
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.45) }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    Column {
        x: 80
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        spacing: 14
        Text {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: "white"; font.family: "JetBrains Mono"; font.pixelSize: 72; font.weight: Font.Light
        }
        Text {
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: Qt.rgba(1, 1, 1, 0.75); font.family: Theme.font; font.pixelSize: 18
        }
        Item {
            width: 300; height: 48
            PasswordPill {
                lock: root.lock
                opacity: root.lock.authMode ? 1 : 0
                x: root.lock.authMode ? 0 : -30
                Behavior on opacity { NumberAnimation { duration: Anim.normal } }
                Behavior on x { NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } }
            }
        }
    }
}
