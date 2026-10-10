// Fluid SDDM theme (Qt 6). Wallpaper with a frosted card in the middle: clock,
// avatar, user + password, session picker and power buttons. Colours and the
// wallpaper come from theme.conf, written by install/sddm.sh.
import QtQuick
import QtQuick.Effects

Item {
    id: root

    readonly property color accent: config.accent || "#c4bca4"
    readonly property color onAccent: config.onAccent || "#0e0c0c"
    readonly property color panel: config.panel || "#0e0c0c"
    readonly property color fg: config.fg || "#ffffff"
    readonly property color fgDim: config.fgDim || "#a7a097"
    readonly property string font: config.font || "Roboto"
    readonly property string clockFont: config.clockFont || "JetBrains Mono"

    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string status: ""
    property bool busy: false

    function login() {
        if (busy || !userField.text) return;
        busy = true;
        status = "";
        sddm.login(userField.text, passField.text, sessionIndex);
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            root.status = "Wrong password";
            passField.text = "";
            passField.forceActiveFocus();
            shake.restart();
        }
        function onLoginSucceeded() { root.status = ""; }
    }

    // ---- Background --------------------------------------------------------
    Image {
        id: wall
        anchors.fill: parent
        source: config.background ? Qt.resolvedUrl(config.background) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    Rectangle { anchors.fill: parent; color: root.panel; visible: wall.status !== Image.Ready }

    // Frosted card in the middle: the wallpaper blurred inside a rounded
    // rectangle (mask), tinted with the panel colour
    Item {
        id: glass
        anchors.centerIn: parent
        width: 440
        height: content.implicitHeight + 80
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        blurEnabled: true
        blurMax: 64
        blur: 1.0
        brightness: -0.15
        maskEnabled: true
        maskSource: cardMask
    }
    Item {
        id: cardMask
        anchors.fill: parent
        layer.enabled: true
        visible: false
        Rectangle { x: glass.x; y: glass.y; width: glass.width; height: glass.height; radius: 28 }
    }
    Rectangle {
        x: glass.x; y: glass.y; width: glass.width; height: glass.height
        radius: 28
        color: root.panel
        opacity: 0.78          // readable on busy wallpapers even where blur isn't available
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)
    }

    // ---- Panel content ------------------------------------------------------------
    Column {
        id: content
        anchors.centerIn: glass
        width: glass.width - 80
        spacing: 16

        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.fg
            font.family: root.clockFont; font.pixelSize: 96; font.weight: Font.Bold
            function update() { text = Qt.formatTime(new Date(), "HH:mm"); date.text = Qt.formatDate(new Date(), "dddd, d MMMM"); }
            Component.onCompleted: update()
            Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.update() }
        }
        Text {
            id: date
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.fgDim
            font.family: root.font; font.pixelSize: 20
        }

        Item { width: 1; height: 10 }

        // Avatar: the user's initial in an accent circle
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 92; height: 92; radius: 46
            color: root.accent
            Text {
                anchors.centerIn: parent
                text: (userField.text || "?").charAt(0).toUpperCase()
                color: root.onAccent
                font.family: root.font; font.pixelSize: 40; font.weight: Font.Bold
            }
        }

        // Username (prefilled with the last user; click to change)
        Rectangle {
            width: parent.width; height: 48; radius: 24
            color: Qt.rgba(1, 1, 1, 0.08)
            border.width: userField.activeFocus ? 2 : 0
            border.color: root.accent
            TextInput {
                id: userField
                anchors.fill: parent; anchors.leftMargin: 22; anchors.rightMargin: 22
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                color: root.fg
                font.family: root.font; font.pixelSize: 17
                text: userModel.lastUser
                KeyNavigation.tab: passField
                Keys.onReturnPressed: passField.forceActiveFocus()
            }
        }

        // Password
        Rectangle {
            id: passBox
            width: parent.width; height: 48; radius: 24
            color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 2
            border.color: root.status ? "#e5484d" : (passField.activeFocus ? root.accent : "transparent")
            transform: Translate { id: shakeX }
            TextInput {
                id: passField
                anchors.fill: parent; anchors.leftMargin: 22; anchors.rightMargin: 56
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: root.fg
                font.family: root.font; font.pixelSize: 17
                focus: true
                KeyNavigation.backtab: userField
                Keys.onReturnPressed: root.login()
                Keys.onEnterPressed: root.login()
                Text {
                    anchors.centerIn: parent
                    visible: !passField.text
                    text: root.busy ? "Logging in…" : (root.status || "Password")
                    color: root.status ? "#e5484d" : root.fgDim
                    font: passField.font
                }
            }
            // Go button
            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                width: 38; height: 38; radius: 19
                color: goArea.containsMouse ? Qt.lighter(root.accent, 1.1) : root.accent
                Text { anchors.centerIn: parent; text: "→"; color: root.onAccent; font.pixelSize: 20; font.weight: Font.Bold }
                MouseArea { id: goArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.login() }
            }
            SequentialAnimation {
                id: shake
                NumberAnimation { target: shakeX; property: "x"; to: -14; duration: 50 }
                NumberAnimation { target: shakeX; property: "x"; to: 14; duration: 70 }
                NumberAnimation { target: shakeX; property: "x"; to: -8; duration: 60 }
                NumberAnimation { target: shakeX; property: "x"; to: 0; duration: 60 }
            }
        }

        // Session: click to cycle (Sway, Sway (NVIDIA), ...)
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            height: 32; radius: 16
            width: sessionText.implicitWidth + 30
            color: sessArea.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.06)
            visible: sessionModel.rowCount() > 0
            Text {
                id: sessionText
                anchors.centerIn: parent
                color: root.fgDim
                font.family: root.font; font.pixelSize: 14
                // reading count makes this re-evaluate once the session items exist
                text: "Session: " + (sessionNames.count > root.sessionIndex ? sessionNames.itemAt(root.sessionIndex).name : "")
                      + (sessionModel.rowCount() > 1 ? "  ›" : "")
            }
            MouseArea {
                id: sessArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
            }
            // Reads the session names out of the model
            Repeater {
                id: sessionNames
                model: sessionModel
                Item { required property string name; visible: false }
            }
        }
    }

    // ---- Power buttons ---------------------------------------------------------------
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        spacing: 12
        Repeater {
            model: [
                { t: "Sleep", show: sddm.canHibernate || sddm.canSuspend, f: () => sddm.canSuspend ? sddm.suspend() : sddm.hibernate() },
                { t: "Restart", show: sddm.canReboot, f: () => sddm.reboot() },
                { t: "Shut down", show: sddm.canPowerOff, f: () => sddm.powerOff() }
            ].filter(b => b.show)
            Rectangle {
                required property var modelData
                height: 36; radius: 18
                width: pbText.implicitWidth + 32
                color: pbArea.containsMouse ? root.accent : Qt.rgba(root.panel.r, root.panel.g, root.panel.b, 0.78)
                Text { id: pbText; anchors.centerIn: parent; text: parent.modelData.t; color: pbArea.containsMouse ? root.onAccent : root.fg; font.family: root.font; font.pixelSize: 14 }
                MouseArea { id: pbArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData.f() }
            }
        }
    }

    Component.onCompleted: passField.forceActiveFocus()
}
