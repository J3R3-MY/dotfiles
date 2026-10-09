import QtQuick
import Quickshell
import "../common"
import "../services"

// Workspace buttons for one output, styled like the old waybar ones
// (dark box, 2px border, number + icon). The focused-workspace highlight is a
// single rectangle that slides and resizes between buttons instead of each
// button just changing colour.
Item {
    id: root

    required property string screenName
    readonly property var workspaces: Sway.workspacesFor(screenName)
    readonly property int activeIndex: workspaces.findIndex(w => w.active)
    readonly property bool outputFocused: workspaces.some(w => w.focused)

    implicitHeight: Theme.pillHeight
    implicitWidth: row.implicitWidth

    Behavior on implicitWidth {
        NumberAnimation { duration: Anim.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized }
    }

    // Sliding highlight
    Rectangle {
        id: highlight
        // repeater.count is read so this re-evaluates once delegates exist
        readonly property Item target: repeater.count > 0 && root.activeIndex >= 0 ? repeater.itemAt(root.activeIndex) : null
        visible: target !== null
        x: target ? target.x : 0
        width: target ? target.width : 0
        height: parent.height
        radius: 5
        color: root.outputFocused ? Theme.accent : Theme.surfaceHi
        Behavior on x { NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.spring } }
        Behavior on width { NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } }
        Behavior on color { ColorAnimation { duration: Anim.normal } }
    }

    Row {
        id: row
        spacing: 6

        Repeater {
            id: repeater
            // ScriptModel diffs by identity, so existing buttons survive when a
            // workspace is added/removed and only the new one animates in
            model: ScriptModel { values: root.workspaces }

            delegate: Item {
                id: btn
                required property var modelData
                required property int index
                readonly property bool isActive: index === root.activeIndex
                readonly property string icon: Icons.workspaces[String(modelData.number)] || ""

                height: Theme.pillHeight
                width: label.implicitWidth + 18

                // Entry animation for newly created workspaces
                scale: 0.6
                opacity: 0
                Component.onCompleted: { scale = 1; opacity = 1; }
                Behavior on scale { NumberAnimation { duration: Anim.normal; easing.type: Easing.OutBack } }
                Behavior on opacity { NumberAnimation { duration: Anim.normal } }

                Rectangle {
                    anchors.fill: parent
                    radius: 5
                    color: btn.modelData.urgent ? Theme.urgent : (btn.isActive ? "transparent" : Theme.bg)
                    border.width: 2
                    border.color: btn.isActive ? "transparent" : (hover.containsMouse ? Theme.accent : Theme.border)
                    Behavior on color { ColorAnimation { duration: Anim.normal } }
                    Behavior on border.color { ColorAnimation { duration: Anim.fast } }
                }

                Row {
                    id: label
                    anchors.centerIn: parent
                    spacing: 2
                    Text {
                        text: btn.modelData.name
                        color: btn.isActive && root.outputFocused ? Theme.onPill : Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: Anim.normal } }
                    }
                    Glyph {
                        visible: btn.icon.length > 0
                        text: " " + btn.icon
                        color: btn.isActive && root.outputFocused ? Theme.onPill : Theme.fg
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: Anim.normal } }
                    }
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Sway.focusWorkspace(btn.modelData)
                }
            }
        }
    }

    // waybar had disable-scroll: true, so scrolling is deliberately not bound
}
