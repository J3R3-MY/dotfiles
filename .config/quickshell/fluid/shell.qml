//@ pragma IconTheme yet-another-monochrome-icon-set
// Fluid shell for sway. Run with `qs -c fluid` (started by fluid-launch.sh).
import QtQuick
import Quickshell
import "common"
import "services"
import "bar"
import "wallpaper"

ShellRoot {
    // Instantiate singletons with side effects up front: the IPC handler and
    // the notification server must exist before anything opens them.
    property var _fluid: Fluid
    property var _notifs: Notifs
    // System password prompts (polkit agent) go to the island
    property var _auth: Auth
    // Night light runs from login, not only once the control center opened
    property var _night: NightLight

    Variants {
        model: Quickshell.screens
        Background {}
    }

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Variants {
        model: Quickshell.screens
        Overlay {}
    }

    LockScreen {}
}
