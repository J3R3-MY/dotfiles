import QtQuick
import Quickshell
import "../common"

// Split: a solid theme-coloured panel on the left with a stacked clock,
// the wallpaper on the right.
Item {
    id: root
    required property var lock

    SystemClock { id: clock; precision: SystemClock.Minutes }

    LockBackground { anchors.fill: parent; blur: 0.3; dim: 0.1 }

    Rectangle {
        id: panel
        width: parent.width * 0.38
        height: parent.height
        color: Theme.bg
        opacity: 0.94

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 90
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: root.lock.authMode ? -80 : 0
            Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } }
            spacing: -30
            Text { text: Qt.formatDateTime(clock.date, "HH"); color: Theme.clock; font.family: "JetBrains Mono"; font.pixelSize: 180; font.weight: Font.Bold }
            Text { text: Qt.formatDateTime(clock.date, "mm"); color: Theme.fg; font.family: "JetBrains Mono"; font.pixelSize: 180; font.weight: Font.Bold }
            Item { width: 1; height: 40 }
            Text { text: Qt.formatDateTime(clock.date, "dddd").toUpperCase(); color: Theme.fgDim; font.family: Theme.font; font.pixelSize: 20; font.letterSpacing: 6 }
            Item { width: 1; height: 34 }
            Text { text: Qt.formatDateTime(clock.date, "d MMMM yyyy"); color: Theme.fg; font.family: Theme.font; font.pixelSize: 20 }
        }

        PasswordPill {
            lock: root.lock
            anchors.left: parent.left
            anchors.leftMargin: 90
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 110
            opacity: root.lock.authMode ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Anim.normal } }
        }

        LockStatusRow {
            anchors.left: parent.left
            anchors.leftMargin: 90
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 50
        }
    }
}
