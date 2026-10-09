import QtQuick
import QtQuick.Effects
import Quickshell
import "../common"

// ~/.face in a circle, or the first letter of the user name.
Item {
    id: root

    property string user: ""
    property real size: 96
    width: size; height: size

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.clock
        Text {
            anchors.centerIn: parent
            visible: face.status !== Image.Ready
            text: root.user.charAt(0).toUpperCase()
            color: Theme.onPill; font.family: Theme.font; font.pixelSize: root.size * 0.42; font.weight: Font.Bold
        }
    }
    Image {
        id: face
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/.face"
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
