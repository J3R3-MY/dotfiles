import QtQuick
import Quickshell
import "../common"
import "../services"

// Notification popups, top-right under the bar. They slide in from the edge,
// expire on their own (paused while hovered) and stay in the control center
// history afterwards — closing one with × dismisses it for good.
Column {
    id: root

    width: 380
    spacing: 10

    add: Transition {
        ParallelAnimation {
            NumberAnimation { property: "x"; from: 420; to: 0; duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized }
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Anim.normal }
        }
    }
    move: Transition {
        NumberAnimation { properties: "y"; duration: Anim.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized }
    }

    Repeater {
        // ScriptModel keeps existing toasts alive when a new one arrives
        model: ScriptModel { values: Notifs.popups }

        NotificationCard {
            id: toast
            required property var modelData
            width: root.width
            notification: modelData
            border.width: 2
            border.color: critical ? Theme.urgent : Theme.border
            color: Theme.bg
            onClose: Notifs.dismiss(modelData)

            // Critical stays until handled; otherwise app timeout or 5s
            Timer {
                running: !toast.critical && !toast.containsMouseAny
                // D-Bus sends ms; Quickshell's docs say seconds, so accept either
                readonly property real t: toast.modelData.expireTimeout
                interval: t <= 0 ? 5000 : (t < 100 ? t * 1000 : t)
                onTriggered: Notifs.hidePopup(toast.modelData)
            }
            readonly property bool containsMouseAny: hoverH.hovered
            HoverHandler { id: hoverH }
        }
    }
}
