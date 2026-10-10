import QtQuick
import "."

// Panel that drops out of the top-right corner (control center, power,
// network): grows with a spring, fades, Esc closes, takes keyboard focus.
Item {
    id: root

    property bool open: false

    transformOrigin: Item.TopRight
    scale: open ? 1 : 0.85
    opacity: open ? 1 : 0
    visible: opacity > 0
    Behavior on scale { NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.spring } }
    Behavior on opacity { NumberAnimation { duration: Anim.fast } }
    Behavior on height { NumberAnimation { duration: Anim.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } }

    // Override to do something else on Esc (the control center goes back a page)
    function dismiss() { Fluid.closeAll(); }
    Keys.onEscapePressed: dismiss()
    onVisibleChanged: if (visible) forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        z: -1
        radius: Theme.panelRadius
        color: Theme.bg
        border.width: 2
        border.color: Theme.border
    }
}
