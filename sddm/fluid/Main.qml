// Fluid SDDM theme (Qt 6): the lock screen design (LockFace.qml, KeyRing.qml
// and Avatar.qml, copied in from the shell by install/lib.sh). Clock first,
// any key or click shows the key ring; session and power at the bottom.
// Wallpaper and colours: background.jpg + theme.conf, kept in step with the
// desktop by scripts/fluid-sddm-sync.sh.
import QtQuick

Item {
    id: root

    readonly property color accent: config.accent || "#c4bca4"

    property bool authMode: false
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    // the last user, else the first one (single-user laptop: no user field)
    readonly property string user: userModel.lastUser || (userNames.count > 0 ? userNames.itemAt(0).name : "")
    property string status: ""
    property bool busy: false

    function login() {
        if (busy || !user || !passField.text) return;
        busy = true;
        status = "";
        sddm.login(user, passField.text, sessionIndex);
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            root.status = "Wrong password";   // before clearing: the ring turns red, no clear flash
            passField.text = "";
            face.shake();
        }
        function onLoginSucceeded() { root.status = ""; }
    }

    // Password: typed into an invisible field, only the ring reacts
    TextInput {
        id: passField
        width: 1; height: 1; opacity: 0
        echoMode: TextInput.NoEcho
        focus: true
        Keys.onPressed: e => {
            root.authMode = true;
            if (e.key === Qt.Key_Escape) { root.authMode = false; passField.text = ""; e.accepted = true; }
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.login(); e.accepted = true; }
        }
    }

    // Below the design so the bottom row gets its clicks
    MouseArea {
        anchors.fill: parent
        onClicked: { root.authMode = true; passField.forceActiveFocus(); }
    }

    LockFace {
        id: face
        anchors.fill: parent
        wallpaper: config.background ? Qt.resolvedUrl(config.background) : ""
        authMode: root.authMode
        user: root.user
        length: passField.text.length
        busy: root.busy
        status: root.status
        accent: root.accent
        ink: config.onAccent || "#0e0c0c"
        dim: config.fgDim || "#a7a097"
        bg: config.panel || "#0e0c0c"

        // Session (click to cycle: Sway, Sway (NVIDIA), ...) and power, styled like the lock's status row
        Repeater {
            model: [
                { t: (sessionNames.count > root.sessionIndex ? sessionNames.itemAt(root.sessionIndex).name : "")
                     + (sessionModel.rowCount() > 1 ? "  ›" : ""),
                  show: sessionModel.rowCount() > 0, f: () => root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount() },
                { t: "Sleep", show: sddm.canHibernate || sddm.canSuspend, f: () => sddm.canSuspend ? sddm.suspend() : sddm.hibernate() },
                { t: "Restart", show: sddm.canReboot, f: () => sddm.reboot() },
                { t: "Shut down", show: sddm.canPowerOff, f: () => sddm.powerOff() }
            ].filter(b => b.show)
            Text {
                required property var modelData
                text: modelData.t
                color: area.containsMouse ? root.accent : "white"
                opacity: 0.85
                font.family: face.font; font.pixelSize: face.fontSize
                MouseArea { id: area; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData.f() }
            }
        }
    }

    // Read the names out of the models
    Repeater { id: sessionNames; model: sessionModel; Item { required property string name; visible: false } }
    Repeater { id: userNames; model: userModel; Item { required property string name; visible: false } }

    Component.onCompleted: passField.forceActiveFocus()
}
