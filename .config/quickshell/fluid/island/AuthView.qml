import QtQuick
import "../common"
import "../services"

// System password prompt (polkit, see services/Auth.qml): who is asking, why,
// and the password field. Enter authenticates, Esc or a click outside cancels.
Item {
    id: root

    readonly property var flow: Auth.flow

    Timer { id: focusTimer; interval: 50; running: true; onTriggered: pw.forceActiveFocus() }
    Connections {
        target: Auth
        function onFailed() { pw.text = ""; shake.restart(); pw.forceActiveFocus(); }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - 16
        spacing: 10

        Row {
            spacing: 12
            Rectangle {
                width: 38; height: 38; radius: 19
                color: Theme.clock
                Glyph { anchors.centerIn: parent; text: Icons.lock; color: Theme.onPill; size: 17 }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Label { text: Auth.app || "Authentication"; font.pixelSize: Theme.fontSize + 1; font.weight: Font.DemiBold }
                Label { text: "needs your password"; dim: true }
            }
        }

        Label {
            width: parent.width
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            text: root.flow ? root.flow.message : ""
            dim: true
        }

        Rectangle {
            width: parent.width; height: 40; radius: 20
            color: Theme.surfaceHi
            border.width: root.flow && root.flow.supplementaryIsError ? 2 : 0
            border.color: Theme.urgent
            transform: Translate { id: shakeX }
            TextInput {
                id: pw
                anchors.fill: parent
                anchors.leftMargin: 18; anchors.rightMargin: 18
                verticalAlignment: TextInput.AlignVCenter
                echoMode: root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
                passwordCharacter: "•"
                clip: true
                color: Theme.fg
                font.family: Theme.font; font.pixelSize: Theme.fontSize
                enabled: root.flow ? root.flow.isResponseRequired : false
                Keys.onEscapePressed: Fluid.closeAll()
                Keys.onReturnPressed: { Auth.submit(text); text = ""; }
                Keys.onEnterPressed: { Auth.submit(text); text = ""; }
                Text {
                    visible: pw.text.length === 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: !pw.enabled ? "Checking…" : (root.flow && root.flow.inputPrompt ? root.flow.inputPrompt.replace(/:\s*$/, "") : "Password")
                    color: Theme.fgDim; font: pw.font
                }
            }
        }
        Label {
            visible: text.length > 0
            width: parent.width
            wrapMode: Text.Wrap
            text: root.flow ? root.flow.supplementaryMessage : ""
            color: root.flow && root.flow.supplementaryIsError ? Theme.urgent : Theme.fgDim
            size: "sm"
        }

        Row {
            anchors.right: parent.right
            spacing: 8
            Repeater {
                model: [{ t: "Cancel", main: false }, { t: "Authenticate", main: true }]
                Button {
                    required property var modelData
                    height: 32
                    text: modelData.t
                    baseColor: modelData.main ? Theme.clock : "transparent"
                    hoverColor: modelData.main ? Theme.accent : Theme.surfaceHi
                    textColor: modelData.main ? Theme.onPill : Theme.fg
                    onClicked: { if (modelData.main) { Auth.submit(pw.text); pw.text = ""; } else Fluid.closeAll(); }
                }
            }
        }
    }

    SequentialAnimation {
        id: shake
        NumberAnimation { target: shakeX; property: "x"; to: -12; duration: 50 }
        NumberAnimation { target: shakeX; property: "x"; to: 12; duration: 70 }
        NumberAnimation { target: shakeX; property: "x"; to: -6; duration: 60 }
        NumberAnimation { target: shakeX; property: "x"; to: 0; duration: 60 }
    }
}
