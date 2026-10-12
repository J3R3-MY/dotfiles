import QtQuick
import Quickshell
import "../common"
import "../services"

// The lock screen look: LockFace (shared with the SDDM theme) fed with the
// shell's state, theme and wallpaper, battery/network/weather at the bottom.
LockFace {
    id: root
    required property var lock

    wallpaper: Wallpaper.current ? "file://" + Wallpaper.current : ""
    face: "file://" + Quickshell.env("HOME") + "/.face"
    authMode: lock.authMode
    user: lock.user
    length: lock.password.length
    busy: lock.busy
    status: lock.status
    hint: lock.fingerprint ? "Touch the sensor or enter password" : "Enter password"
    accent: Theme.clock; ink: Theme.onPill; dim: Theme.fgDim; bg: Theme.bg
    font: Theme.font; fontSize: Theme.fontSize

    Connections { target: root.lock; function onShake() { root.shake(); } }

    LockStatusRow {}
}
