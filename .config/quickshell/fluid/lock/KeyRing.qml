import QtQuick
import QtQuick.Shapes

// swaylock-style key feedback around the avatar (its child, centred): every key
// lights a short arc at a random spot, so nobody watching can count the
// password. Backspace lights it dimmer, clearing flashes the whole ring, it
// spins while checking and turns red after a wrong password.
// No fluid imports: install/lib.sh copies this file into the SDDM theme too.
Item {
    id: ring

    property real size: 116
    property real thickness: 4
    property color accent: "#c4bca4"
    property color dim: "#a7a097"
    property color errorColor: "#e5484d"
    property bool busy: false
    property bool error: false
    // the password length: growing = key, shrinking = erase, back to 0 = clear
    property int length: 0
    property int last: 0
    default property alias content: inner.data

    width: size; height: size

    onLengthChanged: {
        if (length > last) flash(accent, false);
        else if (length > 0) flash(dim, false);
        else if (last > 0) flash(dim, true);
        last = length;
    }
    function flash(c, full) {
        flashPath.strokeColor = c;
        flashArc.startAngle = Math.random() * 360;
        flashArc.sweepAngle = full ? 360 : 70;
        fade.restart();
    }
    function shake() { shakeAnim.restart(); }

    readonly property real r: (size - thickness) / 2

    Item {
        id: body
        anchors.fill: parent
        transform: Translate { id: shakeX }

        Item { id: inner; anchors.fill: parent }

        // faint base ring
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: "transparent"
                strokeWidth: ring.thickness
                strokeColor: ring.error ? ring.errorColor : Qt.rgba(1, 1, 1, 0.18)
                Behavior on strokeColor { ColorAnimation { duration: 200 } }
                PathAngleArc { centerX: ring.size / 2; centerY: ring.size / 2; radiusX: ring.r; radiusY: ring.r; startAngle: 0; sweepAngle: 360 }
            }
        }

        // key flash
        Shape {
            id: flashShape
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: 0
            ShapePath {
                id: flashPath
                fillColor: "transparent"
                strokeWidth: ring.thickness
                capStyle: ShapePath.RoundCap
                PathAngleArc { id: flashArc; centerX: ring.size / 2; centerY: ring.size / 2; radiusX: ring.r; radiusY: ring.r }
            }
            NumberAnimation on opacity { id: fade; running: false; from: 1; to: 0; duration: 450; easing.type: Easing.InQuad }
        }

        // checking: a quarter arc going round
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            visible: ring.busy
            ShapePath {
                fillColor: "transparent"
                strokeWidth: ring.thickness
                strokeColor: ring.accent
                capStyle: ShapePath.RoundCap
                PathAngleArc { centerX: ring.size / 2; centerY: ring.size / 2; radiusX: ring.r; radiusY: ring.r; startAngle: -90; sweepAngle: 90 }
            }
            RotationAnimator on rotation { running: ring.busy; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
        }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: shakeX; property: "x"; to: -14; duration: 50 }
        NumberAnimation { target: shakeX; property: "x"; to: 14; duration: 70 }
        NumberAnimation { target: shakeX; property: "x"; to: -8; duration: 60 }
        NumberAnimation { target: shakeX; property: "x"; to: 0; duration: 60 }
    }
}
