import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "common"
import "services"

// Lock screen (ext-session-lock, which sway supports). Blurred wallpaper and a
// big clock; any key or click slides in the avatar + password pill.
// Triggered by fluid-lock.sh ($mod+Shift+s, idle, before sleep) or the
// lock buttons in the panels. swaylock stays as fallback when the shell
// isn't running.
//
// If the shell dies while locked, sway keeps the session locked; the shell
// re-locks on restart (marker file in $XDG_RUNTIME_DIR). Manual way out from a
// TTY: WAYLAND_DISPLAY=wayland-1 swaylock
Scope {
    id: root

    readonly property string marker: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/fluid-locked"
    readonly property string user: Quickshell.env("USER") || ""

    property bool authMode: false        // false: clock only, true: password visible
    property string password: ""
    property string status: ""
    property bool busy: false
    property int failures: 0

    function lock() {
        if (sessionLock.locked) return;
        authMode = false;
        password = "";
        status = "";
        sessionLock.locked = true;
    }

    function showAuth() {
        if (authMode) return;
        authMode = true;
        if (!pam.active) pam.start();
    }

    function submit() {
        if (busy || password.length === 0) return;
        if (!pam.active) pam.start();
        if (pam.responseRequired) {
            busy = true;
            status = "";
            pam.respond(password);
        } else {
            pendingSubmit = true;
        }
    }
    property bool pendingSubmit: false

    Connections {
        target: Fluid
        function onLockRequested() { root.lock(); }
    }

    PamContext {
        id: pam
        // Same stack as a normal login; swaylock's file would work too
        config: "login"
        onResponseRequiredChanged: {
            if (responseRequired && root.pendingSubmit) {
                root.pendingSubmit = false;
                root.submit();
            }
        }
        onCompleted: result => {
            root.busy = false;
            if (result === PamResult.Success) {
                root.failures = 0;
                root.password = "";
                sessionLock.locked = false;
            } else {
                root.failures++;
                root.password = "";
                root.status = "Wrong password";
                root.shake();
                restart.start();
            }
        }
        onError: err => {
            root.busy = false;
            root.status = "Authentication error";
            restart.start();
        }
    }
    Timer { id: restart; interval: 300; onTriggered: if (sessionLock.locked) pam.start() }

    signal shake()

    WlSessionLock {
        id: sessionLock
        locked: false
        onLockedChanged: {
            Fluid.locked = locked;
            Quickshell.execDetached(locked ? ["touch", root.marker] : ["rm", "-f", root.marker]);
            if (!locked) { root.authMode = false; pam.abort(); }
        }

        WlSessionLockSurface {
            id: surface
            color: "black"

            Item {
                id: screenRoot
                anchors.fill: parent
                focus: true

                Keys.onPressed: e => {
                    if (!root.authMode) { root.showAuth(); }
                    if (e.key === Qt.Key_Escape) { root.authMode = false; root.password = ""; e.accepted = true; return; }
                    if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.submit(); e.accepted = true; return; }
                    if (e.key === Qt.Key_Backspace) { root.password = root.password.slice(0, -1); e.accepted = true; return; }
                    if (e.text && e.text.length === 1 && e.text >= " ") { root.password += e.text; e.accepted = true; }
                }

                // Wallpaper, blurred more once the password shows
                Image {
                    id: wp
                    anchors.fill: parent
                    source: Wallpaper.current ? "file://" + Wallpaper.current : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: surface.width / 2
                    visible: false
                }
                MultiEffect {
                    anchors.fill: parent
                    source: wp
                    blurEnabled: true
                    blurMax: 64
                    blur: root.authMode ? 1.0 : 0.6
                    brightness: root.authMode ? -0.25 : -0.1
                    Behavior on blur { NumberAnimation { duration: Anim.slow } }
                    Behavior on brightness { NumberAnimation { duration: Anim.slow } }
                }

                SystemClock { id: clock; precision: SystemClock.Minutes }

                // Clock: centred, slides up and shrinks when the password shows
                Column {
                    id: clockCol
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: root.authMode ? parent.height * 0.18 : parent.height * 0.5 - height / 2
                    scale: root.authMode ? 0.6 : 1
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

                // Avatar + password pill
                Column {
                    id: auth
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.55
                    spacing: 18
                    opacity: root.authMode ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Anim.normal } }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 96; height: 96; radius: 48
                        color: Theme.clock
                        clip: true
                        Text {
                            anchors.centerIn: parent
                            visible: face.status !== Image.Ready
                            text: root.user.charAt(0).toUpperCase()
                            color: Theme.onPill; font.family: Theme.font; font.pixelSize: 40; font.weight: Font.Bold
                        }
                        Image {
                            id: face
                            anchors.fill: parent
                            source: "file://" + Quickshell.env("HOME") + "/.face"
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                        }
                        MultiEffect {
                            anchors.fill: parent
                            source: face
                            visible: face.status === Image.Ready
                            maskEnabled: true
                            maskSource: faceMask
                        }
                        Item {
                            id: faceMask
                            anchors.fill: parent
                            layer.enabled: true
                            visible: false
                            Rectangle { anchors.fill: parent; radius: width / 2 }
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.user
                        color: "white"; font.family: Theme.font; font.pixelSize: 18; font.weight: Font.DemiBold
                    }

                    Rectangle {
                        id: pill
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 300; height: 48; radius: 24
                        color: Qt.rgba(0, 0, 0, 0.35)
                        border.width: 2
                        border.color: root.status ? Theme.urgent : Theme.clock

                        // Dots for typed characters
                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Repeater {
                                model: Math.min(root.password.length, 24)
                                Rectangle {
                                    width: 10; height: 10; radius: 5
                                    color: "white"
                                    scale: 0
                                    Component.onCompleted: scale = 1
                                    Behavior on scale { NumberAnimation { duration: Anim.fast; easing.type: Easing.OutBack } }
                                }
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: root.password.length === 0
                            text: root.busy ? "Checking…" : (root.status || "Password")
                            color: root.status ? Theme.urgent : Qt.rgba(1, 1, 1, 0.6)
                            font.family: Theme.font; font.pixelSize: Theme.fontSize
                        }

                        transform: Translate { id: shakeX }
                        SequentialAnimation {
                            id: shakeAnim
                            NumberAnimation { target: shakeX; property: "x"; to: -14; duration: 50 }
                            NumberAnimation { target: shakeX; property: "x"; to: 14; duration: 70 }
                            NumberAnimation { target: shakeX; property: "x"; to: -8; duration: 60 }
                            NumberAnimation { target: shakeX; property: "x"; to: 0; duration: 60 }
                        }
                        Connections { target: root; function onShake() { shakeAnim.restart(); } }
                    }
                }

                // Bottom status
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 30
                    spacing: 24
                    opacity: 0.85
                    Repeater {
                        model: [
                            Battery.available ? Icons.battery(Battery.percent, Battery.charging) + "  " + Battery.percent + "%" : "",
                            Network.connected ? (Network.type === "ethernet" ? Icons.ethernet : Icons.wifi) + "  " + Network.name : "",
                            Weather.ready ? Weather.icon + "  " + Math.round(Weather.temp) + "°" : ""
                        ].filter(t => t)
                        Text {
                            required property string modelData
                            text: modelData
                            color: "white"; font.family: Theme.font; font.pixelSize: Theme.fontSize
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: root.showAuth()
                }
            }
        }
    }

    // Re-lock if we were locked when the shell went down
    Process {
        running: true
        command: ["test", "-e", root.marker]
        onExited: code => { if (code === 0) root.lock(); }
    }
}
