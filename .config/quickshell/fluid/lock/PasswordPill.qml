import QtQuick
import "../common"

// Password field as dots, with the status text and a shake on failure.
// `lock` is the LockScreen state object (password, status, busy, shake()).
Rectangle {
    id: pill

    required property var lock
    property real s: 1            // scale factor (previews draw it small)

    width: 300 * s; height: 48 * s; radius: height / 2
    color: Qt.rgba(0, 0, 0, 0.35)
    border.width: 2 * s
    border.color: lock.status ? Theme.urgent : Theme.clock

    Row {
        anchors.centerIn: parent
        spacing: 8 * pill.s
        Repeater {
            model: Math.min(pill.lock.password.length, 24)
            Rectangle {
                width: 10 * pill.s; height: width; radius: width / 2
                color: "white"
                scale: 0
                Component.onCompleted: scale = 1
                Behavior on scale { NumberAnimation { duration: Anim.fast; easing.type: Easing.OutBack } }
            }
        }
    }
    Text {
        anchors.centerIn: parent
        visible: pill.lock.password.length === 0
        text: pill.lock.busy ? "Checking…" : (pill.lock.status || "Password")
        color: pill.lock.status ? Theme.urgent : Qt.rgba(1, 1, 1, 0.6)
        font.family: Theme.font; font.pixelSize: Theme.fontSize * pill.s
    }

    transform: Translate { id: shakeX }
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: shakeX; property: "x"; to: -14; duration: 50 }
        NumberAnimation { target: shakeX; property: "x"; to: 14; duration: 70 }
        NumberAnimation { target: shakeX; property: "x"; to: -8; duration: 60 }
        NumberAnimation { target: shakeX; property: "x"; to: 0; duration: 60 }
    }
    Connections {
        target: pill.lock
        ignoreUnknownSignals: true
        function onShake() { shakeAnim.restart(); }
    }
}
