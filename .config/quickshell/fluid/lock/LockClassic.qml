import QtQuick
import Quickshell
import "../common"

// Classic: centred clock that slides up when the password pill appears.
Item {
    id: root
    required property var lock

    SystemClock { id: clock; precision: SystemClock.Minutes }

    LockBackground {
        anchors.fill: parent
        blur: root.lock.authMode ? 1.0 : 0.6
        dim: root.lock.authMode ? 0.25 : 0.1
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.lock.authMode ? parent.height * 0.18 : parent.height * 0.5 - height / 2
        scale: root.lock.authMode ? 0.6 : 1
        Behavior on y { NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } }
        Behavior on scale { NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: "white"; font.family: "JetBrains Mono"; font.pixelSize: 140; font.weight: Font.Bold
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: Qt.rgba(1, 1, 1, 0.8); font.family: Theme.font; font.pixelSize: 22
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.55
        spacing: 18
        opacity: root.lock.authMode ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Anim.normal } }
        Avatar { anchors.horizontalCenter: parent.horizontalCenter; user: root.lock.user }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.lock.user
            color: "white"; font.family: Theme.font; font.pixelSize: 18; font.weight: Font.DemiBold
        }
        PasswordPill { anchors.horizontalCenter: parent.horizontalCenter; lock: root.lock }
    }

    LockStatusRow {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
    }
}
