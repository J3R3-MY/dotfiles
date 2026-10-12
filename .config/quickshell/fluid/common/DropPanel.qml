import QtQuick
import Quickshell.Widgets
import "."

// Panel that drops out of the top-right corner (control center, power,
// network): grows with a spring, fades, Esc closes, takes keyboard focus.
Item {
    id: root

    property bool open: false
    // drifting colour blobs behind the content (control center)
    property bool lively: false

    transformOrigin: Item.TopRight
    scale: open ? 1 : 0.85
    opacity: open ? 1 : 0
    visible: opacity > 0
    // fade as one picture: without a layer every tile fades on its own and
    // the translucent ones show what's behind them mid-fade
    layer.enabled: visible && opacity < 1
    Behavior on scale { Spring {} }
    Behavior on opacity { Emphasized { duration: Anim.fast } }
    Behavior on height { NumberAnimation { duration: Anim.normal } }

    // Override to do something else on Esc (the control center goes back a page)
    function dismiss() { Fluid.closeAll(); }
    Keys.onEscapePressed: dismiss()
    onVisibleChanged: if (visible) forceActiveFocus()

    ClippingRectangle {
        anchors.fill: parent
        z: -1
        radius: Theme.panelRadius
        color: Theme.bg
        Blobs { anchors.fill: parent; visible: root.lively; strength: 0.3 }
        Rectangle {
            anchors.fill: parent
            radius: Theme.panelRadius
            color: "transparent"
            border.width: 2
            border.color: Theme.border
        }
    }
}
