import QtQuick
import "."

// NumberAnimation on the emphasized curve (Anim.normal by default)
NumberAnimation { duration: Anim.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized }
