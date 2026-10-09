import QtQuick
import Quickshell
import Quickshell.Wayland
import "common"
import "services"
import "island"
import "panels"

// One transparent full-screen layer per output holding everything that floats:
// island, control center, power panel, toasts, OSD. The input mask makes it click-through
// except where something is drawn; while a panel is open the whole surface
// catches clicks so clicking outside closes it.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData
    readonly property string screenName: modelData.name
    readonly property bool isFocusedScreen: Fluid.focusedScreen === screenName || Fluid.focusedScreen === ""

    readonly property bool modal: island.open || cc.open || power.open || net.open

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "fluid-overlay"
    WlrLayershell.keyboardFocus: modal ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: win.modal ? catcher : null
        Region { item: island }
        // Hidden items must not keep their rectangle in the mask, or the closed
        // control center would swallow clicks meant for windows underneath
        Region { item: cc.visible ? cc : null }
        Region { item: power.visible ? power : null }
        Region { item: net.visible ? net : null }
        Region { item: hotCorner }
        Region { item: toasts.visible ? toasts : null }
    }

    // Click-outside-to-close
    MouseArea {
        id: catcher
        anchors.fill: parent
        enabled: win.modal
        onClicked: Fluid.closeAll()
    }

    Island {
        id: island
        screenName: win.screenName
        anchors.horizontalCenter: parent.horizontalCenter
        y: (Theme.barHeight - Theme.pillHeight) / 2
    }

    // Hover the very top-right corner for the control center
    Item {
        id: hotCorner
        anchors.top: parent.top
        anchors.right: parent.right
        width: 4
        height: 4
        HoverHandler {
            onHoveredChanged: if (hovered) dwell.restart(); else dwell.stop()
        }
        Timer {
            id: dwell
            interval: 180
            onTriggered: if (!Fluid.ccOpen) Fluid.toggleControlCenter(win.screenName)
        }
    }

    ControlCenter {
        id: cc
        screenName: win.screenName
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight + 6
        anchors.right: parent.right
        anchors.rightMargin: 10
    }

    PowerPanel {
        id: power
        screenName: win.screenName
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight + 6
        anchors.right: parent.right
        anchors.rightMargin: 10
    }

    NetPanel {
        id: net
        screenName: win.screenName
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight + 6
        anchors.right: parent.right
        anchors.rightMargin: 10
    }

    Toasts {
        id: toasts
        visible: win.isFocusedScreen && !cc.open && !power.open && !net.open
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight + 6
        anchors.right: parent.right
        anchors.rightMargin: 10
    }

    // Wrapper so the OSD's own fade-out isn't cut off by the screen check
    Item {
        visible: win.isFocusedScreen
        anchors.fill: parent
        Osd {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 80
        }
    }
}
