import QtQuick
import QtQuick.Shapes
import Quickshell
import "../common"

// "Orbit" layout: the active thing (connected network or device) sits in a big
// circle in the middle, everything else orbits around it on thin spokes.
//  - satellites are keyed by title, so a rescan moves existing ones instead of
//    rebuilding them; position changes glide on a spring
//  - spokes are curves bound to the satellites' animated positions (no canvas
//    repaints); each bends a little and sways slowly
//  - the whole ring drifts slowly so the page never looks frozen
Item {
    id: root

    // { title, subtitle, icon, active }
    property var center: ({ title: "", subtitle: "", icon: "", active: false })
    // [{ title, subtitle, icon, active }]
    property var items: []
    property bool busy: false
    signal itemClicked(int index)
    signal centerClicked()

    implicitHeight: 330

    readonly property real rx: width / 2 - 64
    readonly property real ry: height / 2 - 36
    property real spread: 0
    property real drift: 0
    property real sway: 0
    Component.onCompleted: spread = 1
    Behavior on spread { Spring { duration: 650 } }
    NumberAnimation on drift { from: 0; to: 2 * Math.PI; duration: 120000; loops: Animation.Infinite; running: root.visible }
    NumberAnimation on sway { from: 0; to: 2 * Math.PI; duration: 7000; loops: Animation.Infinite; running: root.visible }

    function angleFor(i) {
        const n = Math.max(1, items.length);
        return -Math.PI / 2 + i / n * 2 * Math.PI + (n % 2 ? 0 : Math.PI / n);
    }

    // Soft rings behind the centre, breathing a little
    Repeater {
        model: 2
        Rectangle {
            required property int index
            anchors.centerIn: parent
            width: 150 + index * 70; height: width; radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: Theme.border
            opacity: 0.5 - index * 0.2
            SequentialAnimation on scale {
                loops: Animation.Infinite
                running: root.visible
                NumberAnimation { to: 1.1; duration: 2400 + index * 600; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 2400 + index * 600; easing.type: Easing.InOutSine }
            }
        }
    }

    Repeater {
        id: sats
        model: ScriptModel { values: root.items; objectProp: "title" }

        Item {
            id: sat
            required property var modelData
            required property int index
            // Slot angle springs when satellites are added/removed; the slow
            // drift is added on top directly so it never fights the spring
            property real slot: root.angleFor(index)
            Behavior on slot { Spring { duration: 700 } }
            readonly property real px: root.width / 2 + root.rx * root.spread * Math.cos(slot + root.drift)
            readonly property real py: root.height / 2 + root.ry * root.spread * Math.sin(slot + root.drift)
            anchors.fill: parent

            // Spoke from the centre to this satellite: a quadratic curve whose
            // control point sits off the midpoint, swinging slowly sideways
            Shape {
                id: spoke
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                readonly property real cx: root.width / 2
                readonly property real cy: root.height / 2
                readonly property real dx: sat.px - cx
                readonly property real dy: sat.py - cy
                readonly property real len: Math.max(1, Math.sqrt(dx * dx + dy * dy))
                readonly property real bend: len * (0.12 + 0.07 * Math.sin(root.sway + sat.index * 1.7)) * (sat.index % 2 ? 1 : -1)
                readonly property real ctrlX: cx + dx / 2 - dy / len * bend
                readonly property real ctrlY: cy + dy / 2 + dx / len * bend

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: sat.modelData.active ? Theme.clock : Qt.alpha(Theme.fg, 0.2)
                    strokeWidth: sat.modelData.active ? 1.5 : 1.2
                    capStyle: ShapePath.RoundCap
                    startX: spoke.cx; startY: spoke.cy
                    PathQuad { x: sat.px; y: sat.py; controlX: spoke.ctrlX; controlY: spoke.ctrlY }
                }
            }

            Rectangle {
                id: chip
                width: Math.min(150, satRow.implicitWidth + 22); height: 40; radius: 20
                x: sat.px - width / 2
                y: sat.py - height / 2
                color: sat.modelData.active ? Theme.clock : (satArea.containsMouse ? Theme.surfaceHi : Theme.surface)
                border.width: 1
                border.color: sat.modelData.active ? Theme.clock : Theme.border
                opacity: 0
                scale: satArea.containsMouse ? 1.06 : 1
                Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: Anim.normal } }
                Behavior on scale { Bounce {} }
                Behavior on color { ColorAnimation { duration: Anim.normal } }

                Row {
                    id: satRow
                    anchors.centerIn: parent
                    spacing: 7
                    Glyph { anchors.verticalCenter: parent.verticalCenter; text: sat.modelData.icon; size: 14; color: sat.modelData.active ? Theme.onPill : Theme.fg }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Label {
                            width: Math.min(implicitWidth, 100); elide: Text.ElideRight
                            text: sat.modelData.title
                            color: sat.modelData.active ? Theme.onPill : Theme.fg
                            size: "xs"
                        }
                        Label {
                            visible: text.length > 0
                            width: Math.min(implicitWidth, 100); elide: Text.ElideRight
                            text: sat.modelData.subtitle || ""
                            color: sat.modelData.active ? Theme.onPill : Theme.fgDim
                            font.pixelSize: 9
                        }
                    }
                }
                MouseArea { id: satArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.itemClicked(sat.index) }
            }
        }
    }

    // Centre (drawn last so spokes start underneath it)
    Rectangle {
        id: hub
        anchors.centerIn: parent
        width: 118; height: 118; radius: 59
        color: root.center.active ? Theme.clock : Theme.surfaceHi
        Behavior on color { ColorAnimation { duration: Anim.normal } }
        scale: hubArea.pressed ? 0.95 : 1
        Behavior on scale { Bounce {} }

        // Ripple while scanning / connecting
        Rectangle {
            anchors.centerIn: parent
            width: parent.width; height: width; radius: width / 2
            color: "transparent"
            border.width: 3
            border.color: Theme.clock
            opacity: 0
            SequentialAnimation on opacity {
                running: root.busy
                loops: Animation.Infinite
                NumberAnimation { from: 0.8; to: 0; duration: 1100 }
            }
            SequentialAnimation on scale {
                running: root.busy
                loops: Animation.Infinite
                NumberAnimation { from: 1; to: 1.4; duration: 1100; easing.type: Easing.OutCubic }
            }
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - 16
            spacing: 2
            Glyph { anchors.horizontalCenter: parent.horizontalCenter; text: root.center.icon; size: 26; color: root.center.active ? Theme.onPill : Theme.fg }
            Label {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                text: root.center.title
                color: root.center.active ? Theme.onPill : Theme.fg
                size: "sm"; font.weight: Font.DemiBold
            }
            Label {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                visible: text.length > 0
                text: root.center.subtitle
                color: root.center.active ? Theme.onPill : Theme.fgDim
                size: "xs"
            }
        }
        MouseArea { id: hubArea; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.centerClicked() }
    }
}
