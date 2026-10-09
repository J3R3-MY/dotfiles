import QtQuick
import QtQuick.Effects
import "../common"
import "../services"

// Wallpaper with adjustable blur and dimming, shared by all lock designs.
Item {
    id: root

    property real blur: 0.6
    property real dim: 0.1

    Image {
        id: wp
        anchors.fill: parent
        source: Wallpaper.current ? "file://" + Wallpaper.current : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: Math.max(640, root.width / 2)
        asynchronous: true
        visible: false
    }
    Rectangle { anchors.fill: parent; color: Theme.bg; visible: wp.status !== Image.Ready }
    MultiEffect {
        anchors.fill: parent
        source: wp
        visible: wp.status === Image.Ready
        blurEnabled: root.blur > 0
        blurMax: 64
        blur: root.blur
        brightness: -root.dim
        Behavior on blur { NumberAnimation { duration: Anim.slow } }
        Behavior on brightness { NumberAnimation { duration: Anim.slow } }
    }
}
