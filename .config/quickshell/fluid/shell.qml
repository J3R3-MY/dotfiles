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
    // Starts counting screen time right away, not when the dashboard opens
    property var _screentime: ScreenTime

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
