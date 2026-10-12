import QtQuick
import Quickshell
import "../common"
import "../services"

// Bitwarden ($mod+Shift+p). Locked: master password field. Unlocked: search,
// Enter copies the password, Shift+Enter the username, Ctrl+T the TOTP code.
Item {
    id: root

    property var results: Vault.search(search.text)

    Component.onCompleted: { Vault.refresh(); focusTimer.start(); }
    Timer { id: focusTimer; interval: 50; onTriggered: Vault.unlocked ? search.focusInput() : pw.forceActiveFocus() }
    Connections { target: Vault; function onUnlockedChanged() { if (Vault.unlocked) search.focusInput(); } }

    function pick(what) {
        const item = results[list.currentIndex];
        if (!item) return;
        Vault.copy(item, what);
        if (what !== "username") Fluid.closeAll();
    }

    // ---- Header -----------------------------------------------------------
    Item {
        id: header
        width: parent.width
        height: 30
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Glyph { text: Icons.g(0xf084); color: Theme.clock; size: 18; anchors.verticalCenter: parent.verticalCenter }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Bitwarden" + (Vault.email ? "  ·  " + Vault.email : "")
                color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.weight: Font.DemiBold
            }
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            visible: Vault.unlocked
            Repeater {
                model: [{ t: "Sync", f: () => Vault.sync() }, { t: Icons.lock + "  Lock", f: () => Vault.lock() }]
                Chip {
                    required property var modelData
                    text: modelData.t
                    onClicked: modelData.f()
                }
            }
        }
    }

    // ---- Not installed / logged out --------------------------------------------
    Column {
        anchors.centerIn: parent
        spacing: 14
        visible: Vault.status === "missing" || Vault.status === "unauthenticated"
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Vault.status === "missing" ? "The Bitwarden CLI (bw) isn't installed" : "Not logged in to Bitwarden"
            color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize
        }
        Rectangle {
            visible: Vault.status === "unauthenticated"
            anchors.horizontalCenter: parent.horizontalCenter
            width: 220; height: 40; radius: 14
            color: Theme.clock
            Text { anchors.centerIn: parent; text: "Log in (opens a terminal)"; color: Theme.onPill; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Vault.login() }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Vault.status === "unauthenticated"
            text: "Self-hosted? Run  bw config server <url>  first."
            color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4
        }
    }

    // ---- Locked: master password --------------------------------------------------
    Column {
        anchors.centerIn: parent
        spacing: 12
        visible: Vault.status === "locked" || (Vault.status === "unlocked" && !Vault.unlocked)
        Glyph { anchors.horizontalCenter: parent.horizontalCenter; text: Icons.lock; size: 34; color: Theme.clock }
        Rectangle {
            id: pwBox
            width: 320; height: 46; radius: 23
            color: Theme.surfaceHi
            border.width: Vault.error ? 2 : 0
            border.color: Theme.urgent
            TextInput {
                id: pw
                anchors.fill: parent
                anchors.leftMargin: 20; anchors.rightMargin: 20
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: Theme.fg
                font.family: Theme.font; font.pixelSize: Theme.fontSize + 1
                enabled: !Vault.busy
                Keys.onEscapePressed: Fluid.closeAll()
                Keys.onReturnPressed: { Vault.unlock(text); text = ""; }
                Text {
                    visible: pw.text.length === 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: Vault.busy ? "Unlocking…" : "Master password"
                    color: Theme.fgDim; font: pw.font
                }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Vault.error.length > 0
            text: Vault.error
            color: Theme.urgent; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
        }
    }

    // ---- Unlocked: search + list --------------------------------------------------
    Item {
        anchors.top: header.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        width: parent.width
        visible: Vault.unlocked

        SearchField {
            id: search
            width: parent.width
            placeholder: "Search vault   (Enter: password · Shift+Enter: username · Ctrl+T: code)"
            onTextChanged: list.currentIndex = 0
            onUp: list.decrementCurrentIndex()
            onDown: list.incrementCurrentIndex()
            onAccepted: root.pick("password")
            onShortcut: (key, mods) => {
                if (key === Qt.Key_Return && (mods & Qt.ShiftModifier)) root.pick("username");
                else if (key === Qt.Key_T) root.pick("totp");
            }
        }

        ListView {
            id: list
            anchors.top: search.bottom
            anchors.topMargin: 10
            anchors.bottom: parent.bottom
            width: parent.width
            clip: true
            spacing: 2
            model: ScriptModel { values: root.results.slice(0, 80); objectProp: "id" }
            highlightMoveDuration: Anim.fast
            highlight: Rectangle { radius: 12; color: Theme.surfaceHi }
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                width: list.width
                height: 50

                Glyph {
                    id: ico
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: ({ 1: Icons.g(0xf0ac), 2: Icons.g(0xf15c), 3: Icons.g(0xf09d), 4: Icons.g(0xf2bb) })[row.modelData.type] || Icons.g(0xf084)
                    color: Theme.fgDim
                }
                Column {
                    anchors.left: ico.right; anchors.leftMargin: 14
                    anchors.right: actions.left; anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    Text { width: parent.width; elide: Text.ElideRight; text: (row.modelData.fav ? "★ " : "") + row.modelData.name; color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
                    Text { width: parent.width; elide: Text.ElideRight; visible: text.length > 0; text: row.modelData.user || row.modelData.uri; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
                }
                Row {
                    id: actions
                    anchors.right: parent.right; anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    opacity: rowArea.containsMouse || list.currentIndex === row.index ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Anim.fast } }
                    Repeater {
                        model: [
                            { t: "user", w: "username", show: row.modelData.user !== "" },
                            { t: "pass", w: "password", show: row.modelData.type === 1 },
                            { t: "code", w: "totp", show: row.modelData.totp }
                        ].filter(a => a.show)
                        Chip {
                            required property var modelData
                            text: modelData.t
                            size: Theme.fontSize - 4
                            onClicked: Vault.copy(row.modelData, modelData.w)
                        }
                    }
                }
                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    z: -1
                    hoverEnabled: true
                    onEntered: list.currentIndex = row.index
                    onClicked: root.pick("password")
                }
            }
        }

        Text {
            anchors.centerIn: list
            visible: list.count === 0
            text: Vault.busy ? "Loading vault…" : "No matches"
            color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
        }
    }

    // Toast for "copied"
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        height: 32; radius: 16
        width: toastText.implicitWidth + 28
        color: Theme.clock
        opacity: Vault.toast ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Anim.normal } }
        Text { id: toastText; anchors.centerIn: parent; text: Vault.toast; color: Theme.onPill; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
    }
}
