import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../common"
import "../services"

// Workspace buttons for one output, styled like the old waybar ones
// (dark box, 2px border, number + icon). The focused-workspace highlight is a
// single rectangle that slides and resizes between buttons instead of each
// button just changing colour.
Item {
    id: root

    required property string screenName
    readonly property var workspaces: Sway.workspacesFor(screenName)
    readonly property int activeIndex: workspaces.findIndex(w => w.active)
    readonly property bool outputFocused: workspaces.some(w => w.focused)

    implicitHeight: Theme.pillHeight
    implicitWidth: row.implicitWidth

    Behavior on implicitWidth {
        Emphasized {}
    }

    // Sliding highlight
    Rectangle {
        id: highlight
        // repeater.count is read so this re-evaluates once delegates exist
        readonly property Item target: repeater.count > 0 && root.activeIndex >= 0 ? repeater.itemAt(root.activeIndex) : null
        visible: target !== null
        x: target ? target.x : 0
        width: target ? target.width : 0
        height: parent.height
        radius: 5
        color: root.outputFocused ? Theme.accent : Theme.surfaceHi
        Behavior on x { Spring {} }
        Behavior on width { Emphasized { duration: Anim.slow } }
        Behavior on color { ColorAnimation { duration: Anim.normal } }
    }

    Row {
        id: row
        spacing: 6

        Repeater {
            id: repeater
            // ScriptModel diffs by identity, so existing buttons survive when a
            // workspace is added/removed and only the new one animates in
            model: ScriptModel { values: root.workspaces }

            delegate: Item {
                id: btn
                required property var modelData
                required property int index
                readonly property bool isActive: index === root.activeIndex
                // the apps open on it (max 3) as real theme icons, sharp at any
                // size; named workspaces like Spotify's "m" show only the icons
                readonly property var appIds: (Sway.apps[modelData.name] || []).slice(0, 3)
                readonly property bool showName: modelData.number >= 0 || appIds.length === 0

                height: Theme.pillHeight
                width: label.implicitWidth + 18

                // Entry animation for newly created workspaces
                scale: 0.6
                opacity: 0
                Component.onCompleted: { scale = 1; opacity = 1; }
                Behavior on scale { Bounce { duration: Anim.normal } }
                Behavior on opacity { NumberAnimation { duration: Anim.normal } }

                Rectangle {
                    anchors.fill: parent
                    radius: 5
                    color: btn.modelData.urgent ? Theme.urgent : (btn.isActive ? "transparent" : Theme.bg)
                    border.width: 2
                    border.color: btn.isActive ? "transparent" : (hover.containsMouse ? Theme.accent : Theme.border)
                    Behavior on color { ColorAnimation { duration: Anim.normal } }
                    Behavior on border.color { ColorAnimation { duration: Anim.fast } }
                }

                Row {
                    id: label
                    anchors.centerIn: parent
                    spacing: 5
                    Label {
                        visible: btn.showName
                        text: btn.modelData.name
                        color: btn.isActive && root.outputFocused ? Theme.onPill : Theme.fg
                        size: "lg"
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: Anim.normal } }
                    }
                    Repeater {
                        model: btn.appIds
                        Item {
                            required property string modelData
                            width: 20
                            height: 20
                            anchors.verticalCenter: parent.verticalCenter
                            Image {
                                anchors.fill: parent
                                // the theme's icon named after the window first (the
                                // Spotify app's desktop entry wants "spotify-launcher",
                                // which only Papirus has, in colour)
                                source: Quickshell.iconPath(parent.modelData, true) || Sway.iconFor(parent.modelData)
                                sourceSize: Qt.size(40, 40)
                                smooth: true
                                mipmap: true
                                // monochrome icon theme: tinted with the theme's accent (the
                                // highlight colour), dark on the highlighted workspace
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    colorization: 1
                                    colorizationColor: btn.isActive && root.outputFocused ? Theme.onPill : Theme.accent
                                    // fades with the number; snapping made the icon flash
                                    // dark-on-dark while the highlight was still sliding over
                                    Behavior on colorizationColor { ColorAnimation { duration: Anim.normal } }
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Sway.focusWorkspace(btn.modelData)
                }
            }
        }
    }

    // waybar had disable-scroll: true, so scrolling is deliberately not bound
}
