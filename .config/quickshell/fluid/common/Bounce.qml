import QtQuick
import "."

// Short overshoot for press feedback and small pops
NumberAnimation { duration: Anim.fast; easing.type: Easing.OutBack }
