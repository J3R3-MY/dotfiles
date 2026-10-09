import QtQuick
import "../common"

// "Orbit" layout from the reference shell: the active thing (connected network
// or device) sits in a big circle in the middle, everything else orbits around
// it, linked by thin lines. Items fly out from the centre when the page opens.
Item {
    id: root

    // { title, subtitle, icon, active }
    property var center: ({ title: "", subtitle: "", icon: "", active: false })
    // [{ title, subtitle, icon, active, strength (0..1, optional) }]
    property var items: []
    property bool busy: false
    signal itemClicked(int index)
    signal centerClicked()

    implicitHeight: 330

    readonly property real rx: width / 2 - 62
    readonly property real ry: height / 2 - 34
    property real spread: 0          // 0 -> 1 on open, drives the fly-out
    Component.onCompleted: spread = 1
    onItemsChanged: lines.requestPaint()
    Behavior on spread { NumberAnimation { duration: Anim.slow + 120; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.spring } }
    onSpreadChanged: lines.requestPaint()

    function pos(i) {
        const n = Math.max(1, items.length);
        const a = -Math.PI / 2 + i / n * 2 * Math.PI + (n % 2 ? 0 : Math.PI / n);
        return { x: width / 2 + rx * spread * Math.cos(a), y: height / 2 + ry * spread * Math.sin(a) };
    }

    Canvas {
        id: lines
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.lineWidth = 1;
            for (let i = 0; i < root.items.length; i++) {
                const p = root.pos(i);
                ctx.strokeStyle = String(root.items[i].active ? Theme.clock : Theme.border);
                ctx.setLineDash(root.items[i].active ? [] : [3, 4]);
                ctx.beginPath();
                ctx.moveTo(width / 2, height / 2);
                ctx.lineTo(p.x, p.y);
                ctx.stroke();
            }
        }
    }

    // Soft rings behind the centre
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
        }
    }

    // Centre
    Rectangle {
        id: hub
        anchors.centerIn: parent
        width: 118; height: 118; radius: 59
        color: root.center.active ? Theme.clock : Theme.surfaceHi
        Behavior on color { ColorAnimation { duration: Anim.normal } }
        scale: hubArea.pressed ? 0.95 : 1
        Behavior on scale { NumberAnimation { duration: Anim.fast; easing.type: Easing.OutBack } }

        // Pulse while scanning / connecting
        Rectangle {
            anchors.centerIn: parent
            width: parent.width; height: width; radius: width / 2
            color: "transparent"
            border.width: 3
            border.color: Theme.clock
            opacity: 0
            SequentialAnimation on scale {
                running: root.busy
                loops: Animation.Infinite
                NumberAnimation { from: 1; to: 1.35; duration: 900; easing.type: Easing.OutCubic }
            }
            SequentialAnimation on opacity {
                running: root.busy
                loops: Animation.Infinite
                NumberAnimation { from: 0.8; to: 0; duration: 900 }
            }
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - 16
            spacing: 2
            Glyph { anchors.horizontalCenter: parent.horizontalCenter; text: root.center.icon; size: 26; color: root.center.active ? Theme.onPill : Theme.fg }
            Text {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                text: root.center.title
                color: root.center.active ? Theme.onPill : Theme.fg
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 3; font.weight: Font.DemiBold
            }
            Text {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                visible: text.length > 0
                text: root.center.subtitle
                color: root.center.active ? Theme.onPill : Theme.fgDim
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 5
            }
        }
        MouseArea { id: hubArea; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.centerClicked() }
    }

    // Satellites
    Repeater {
        model: root.items
        Rectangle {
            id: sat
            required property var modelData
            required property int index
            readonly property var p: root.pos(index)
            width: Math.min(150, satRow.implicitWidth + 22); height: 40; radius: 20
            x: p.x - width / 2
            y: p.y - height / 2
            color: modelData.active ? Theme.clock : (satArea.containsMouse ? Theme.surfaceHi : Theme.surface)
            border.width: 1
            border.color: modelData.active ? Theme.clock : Theme.border
            opacity: root.spread
            scale: satArea.containsMouse ? 1.06 : 1
            Behavior on scale { NumberAnimation { duration: Anim.fast; easing.type: Easing.OutBack } }
            Behavior on color { ColorAnimation { duration: Anim.fast } }

            Row {
                id: satRow
                anchors.centerIn: parent
                spacing: 7
                Glyph { anchors.verticalCenter: parent.verticalCenter; text: sat.modelData.icon; size: 14; color: sat.modelData.active ? Theme.onPill : Theme.fg }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        width: Math.min(implicitWidth, 100); elide: Text.ElideRight
                        text: sat.modelData.title
                        color: sat.modelData.active ? Theme.onPill : Theme.fg
                        font.family: Theme.font; font.pixelSize: Theme.fontSize - 4
                    }
                    Text {
                        visible: text.length > 0
                        width: Math.min(implicitWidth, 100); elide: Text.ElideRight
                        text: sat.modelData.subtitle || ""
                        color: sat.modelData.active ? Theme.onPill : Theme.fgDim
                        font.family: Theme.font; font.pixelSize: 9
                    }
                }
            }
            MouseArea { id: satArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.itemClicked(sat.index) }
        }
    }
}
