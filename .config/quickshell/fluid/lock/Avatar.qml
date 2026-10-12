import QtQuick
import QtQuick.Effects

// An image in a circle, or the first letter of the user name.
// No fluid imports: install/lib.sh copies this file into the SDDM theme too.
Item {
    id: root

    property string user: ""
    property string source: ""
    property real size: 96
    property color color: "#c4bca4"
    property color ink: "#0e0c0c"
    property string font: "Roboto"
    width: size; height: size

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.color
        Text {
            anchors.centerIn: parent
            visible: face.status !== Image.Ready
            text: root.user.charAt(0).toUpperCase()
            color: root.ink; font.family: root.font; font.pixelSize: root.size * 0.42; font.weight: Font.Bold
        }
    }
    Image {
        id: face
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: face
        visible: face.status === Image.Ready
        maskEnabled: true
        maskSource: mask
    }
    Item {
        id: mask
        anchors.fill: parent
        layer.enabled: true
        visible: false
        Rectangle { anchors.fill: parent; radius: width / 2 }
    }
}
