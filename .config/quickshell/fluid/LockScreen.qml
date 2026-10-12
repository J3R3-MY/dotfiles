import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "common"
import "services"
import "lock"

// Lock screen (ext-session-lock, which sway supports). The look is in
// lock/LockClassic.qml; this file only holds the state and talks to PAM. Any key or click shows the password field.
// With a finger enrolled (fprintd-enroll) touching the sensor unlocks too: a
// fingerprint-only PAM check (pam/fluid-fingerprint) runs next to the password one.
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
    property bool fingerprint: false     // fprintd has a finger enrolled for us

    function lock() {
        if (sessionLock.locked) return;
        authMode = false;
        password = "";
        status = "";
        sessionLock.locked = true;
        fpCheck.running = true;
    }

    function unlock() {
        root.failures = 0;
        root.password = "";
        sessionLock.locked = false;
        // also clear directly: after a reload while locked,
        // onLockedChanged doesn't always run on unlock
        persist.locked = false;
        Fluid.locked = false;
        Quickshell.execDetached(["rm", "-f", root.marker]);
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
                root.unlock();
            } else {
                root.failures++;
                root.status = "Wrong password";   // before clearing: the ring turns red, no clear flash
                root.password = "";
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

    // Fingerprint: checked again on every lock, so a new enrollment just works
    Process {
        id: fpCheck
        command: ["sh", "-c", "fprintd-list \"$USER\" 2>/dev/null | grep -q ' - #'"]
        onExited: code => {
            root.fingerprint = code === 0;
            fp.errors = 0;
            if (root.fingerprint && sessionLock.locked && !fp.active) fp.start();
        }
    }
    PamContext {
        id: fp
        property int errors: 0
        configDirectory: Quickshell.shellDir + "/pam"
        config: "fluid-fingerprint"
        onPamMessage: {
            if (messageIsError && sessionLock.locked) {
                root.status = "Fingerprint not recognised";
                root.shake();
            }
        }
        // no match after a few tries or 30 s: just listen again
        onCompleted: result => {
            if (result === PamResult.Success) root.unlock();
            else fpRestart.start();
        }
        // fprintd gone or the sensor busy: retry a few times, then leave it
        onError: { if (++errors < 3) fpRestart.start(); }
    }
    Timer { id: fpRestart; interval: 1000; onTriggered: if (sessionLock.locked && root.fingerprint && !fp.active) fp.start() }

    signal shake()

    WlSessionLock {
        id: sessionLock
        locked: false
        onLockedChanged: {
            Fluid.locked = locked;
            persist.locked = locked;
            Quickshell.execDetached(locked ? ["touch", root.marker] : ["rm", "-f", root.marker]);
            if (!locked) { root.authMode = false; pam.abort(); fp.abort(); }
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

                // Below the design so its buttons (go arrow) get their clicks
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.showAuth()
                }

                LockClassic { anchors.fill: parent; lock: root }
            }
        }
    }

    // Re-lock if we were locked when the shell went down. A hot reload carries
    // the state over in memory; only a real (re)start reads the marker, so a
    // leftover marker can't lock the screen on every config reload.
    PersistentProperties {
        id: persist
        reloadableId: "fluidLock"
        property bool locked: false
        property bool started: false        // survives reloads, false only on a real start
        onLoaded: if (!started) { started = true; markerCheck.running = true; }
        onReloaded: if (locked) root.lock()
    }
    Process {
        id: markerCheck
        command: ["test", "-e", root.marker]
        onExited: code => { if (code === 0) root.lock(); }
    }
}
