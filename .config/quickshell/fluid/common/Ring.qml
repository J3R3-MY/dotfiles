import QtQuick
import "."

// Circular progress ring with a value in the middle and a label under it.
Item {
    id: root

    property real value: 0          // 0..1
    property string text: ""
    property string label: ""
    property color color: Theme.clock
    property real thickness: 5

    implicitWidth: 64
    implicitHeight: 64 + (label ? 20 : 0)

    property real shown: value
    Behavior on shown { Emphasized { duration: Anim.slow } }
    onShownChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        width: 64; height: 64
        anchors.horizontalCenter: parent.horizontalCenter
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const r = width / 2 - root.thickness;
            ctx.lineWidth = root.thickness;
            ctx.lineCap = "round";
            ctx.strokeStyle = String(Theme.surfaceHi);
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, r, 0, 2 * Math.PI);
            ctx.stroke();
            const v = Math.max(0, Math.min(1, root.shown));
            if (v > 0) {
                ctx.strokeStyle = String(root.color);
                ctx.beginPath();
                ctx.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + v * 2 * Math.PI);
                ctx.stroke();
            }
        }
        Label {
            anchors.centerIn: parent
            text: root.text
            size: "sm"; font.weight: Font.DemiBold
        }
    }

    Label {
        visible: root.label.length > 0
        anchors.top: canvas.bottom
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.label
        dim: true
        size: "xs"
    }
}
