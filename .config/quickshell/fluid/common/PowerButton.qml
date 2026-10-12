import QtQuick
import Quickshell
import "."

// One of Fluid.powerActions (sleep, log out, reboot, power off). Destructive
// ones need a second click within 2.5 s: the first turns it red with a "?".
Button {
    id: root

    property var action          // { id, i, tip, cmd, confirm }
    property bool armed: false

    icon: armed ? "?" : action.i
    baseColor: armed ? Theme.urgent : Theme.surface
    hoverColor: armed ? Theme.urgent : Theme.surfaceHi
    Timer { id: disarm; interval: 2500; onTriggered: root.armed = false }
    onClicked: {
        if (action.confirm && !armed) { armed = true; disarm.restart(); return; }
        Fluid.closeAll();
        Quickshell.execDetached(action.cmd);
    }
}
