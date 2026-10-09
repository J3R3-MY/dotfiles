import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "common"
import "services"
import "lock"

// Lock screen (ext-session-lock, which sway supports). The look comes from one
// of the designs in lock/ (picked in the lock style view); this file only holds
// the state and talks to PAM. Any key or click shows the password field.
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

                // The chosen design (lock/Lock*.qml), see LockStyle
                Loader {
                    id: design
                    anchors.fill: parent
                    function load() { setSource("lock/" + LockStyle.file, { lock: root }); }
                    Component.onCompleted: load()
                    Connections { target: LockStyle; function onFileChanged() { design.load(); } }
                }

                MouseArea {
                    anchors.fill: parent
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
