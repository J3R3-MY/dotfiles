import QtQuick
import "."

// NumberAnimation on the spring curve (Anim.slow by default)
NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.spring }
