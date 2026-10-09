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
}
