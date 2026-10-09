import QtQuick
import Quickshell.Widgets
import "../common"
import "../services"

// Now playing ($mod+m / right-click the clock): album art as a spinning
// record, seekable progress, controls, and a 10-band equalizer with presets.
Item {
    id: root

    function fmt(s) {
        s = Math.max(0, Math.floor(s));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    Keys.onEscapePressed: Fluid.closeAll()
    Keys.onSpacePressed: Media.toggle()
    Keys.onLeftPressed: Media.previous()
    Keys.onRightPressed: Media.next()
    Component.onCompleted: { forceActiveFocus(); Equalizer.refresh(); }

    // ---- Player ---------------------------------------------------------------
    Item {
        id: player
        width: parent.width
        height: 170

        Text {
            anchors.centerIn: parent
            visible: !Media.active
            text: "Nothing playing"
            color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize
        }

        // Vinyl: grooves + label (the cover) + spindle hole; spins while playing
        Item {
            id: vinyl
            visible: Media.active
            width: 170; height: 170

            Rectangle {
                id: disc
                anchors.fill: parent
                radius: width / 2
                color: "#111111"
                border.width: 2
                border.color: Theme.border

                Repeater {
                    model: 5
                    Rectangle {
                        required property int index
                        anchors.centerIn: parent
                        width: disc.width - 16 - index * 12; height: width; radius: width / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.06)
                    }
                }

                ClippingRectangle {
                    anchors.centerIn: parent
                    width: 96; height: 96; radius: 48
                    color: Theme.surfaceHi
                    Glyph { anchors.centerIn: parent; text: Icons.music; size: 30; color: Theme.fgDim; visible: art.status !== Image.Ready }
                    Image {
                        id: art
                        anchors.fill: parent
                        source: Media.art
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }
                Rectangle { anchors.centerIn: parent; width: 10; height: 10; radius: 5; color: "#111111" }

                // Pauses in place instead of snapping back to 0°
                NumberAnimation on rotation {
                    from: 0; to: 360
                    duration: 6000
                    loops: Animation.Infinite
                    running: Media.active
                    paused: running && !Media.playing
                }
            }
        }

        Column {
            visible: Media.active
            anchors.left: vinyl.right
            anchors.leftMargin: 22
            anchors.right: parent.right
            anchors.verticalCenter: vinyl.verticalCenter
            spacing: 8

            Text {
                width: parent.width; elide: Text.ElideRight
                text: Media.title
                color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize + 3; font.weight: Font.DemiBold
            }
            Text {
                width: parent.width; elide: Text.ElideRight
                text: Media.artist
                color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
            }

            Item {
                width: parent.width
                height: 18
                visible: Media.length > 0
                Rectangle {
                    width: parent.width; height: 6; radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.surfaceHi
                    Rectangle {
                        height: parent.height; radius: 3
                        width: parent.width * Math.min(1, Media.position / Math.max(1, Media.length))
                        color: Theme.clock
                        Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
                    }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: m => Media.seek(m.x / width) }
            }
            Row {
                width: parent.width
                visible: Media.length > 0
                Text { width: parent.width / 2; text: root.fmt(Media.position); color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
                Text { width: parent.width / 2; horizontalAlignment: Text.AlignRight; text: root.fmt(Media.length); color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
            }

            Row {
                spacing: 14
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: [
                        { icon: Icons.prev, act: () => Media.previous(), big: false },
                        { icon: Media.playing ? Icons.pause : Icons.play, act: () => Media.toggle(), big: true },
                        { icon: Icons.next, act: () => Media.next(), big: false }
                    ]
                    Rectangle {
                        required property var modelData
                        width: modelData.big ? 46 : 36; height: width; radius: width / 2
                        color: modelData.big ? Theme.clock : (ctl.containsMouse ? Theme.surfaceHi : "transparent")
                        scale: ctl.pressed ? 0.88 : 1
                        Behavior on scale { NumberAnimation { duration: Anim.fast; easing.type: Easing.OutBack } }
                        Glyph { anchors.centerIn: parent; text: parent.modelData.icon; color: parent.modelData.big ? Theme.onPill : Theme.fg }
                        MouseArea { id: ctl; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData.act() }
                    }
                }
            }
        }
    }

    // Spotify library shortcut (when spotify_player is set up)
    Rectangle {
        visible: Spotify.state === "ready"
        anchors.right: parent.right
        anchors.top: parent.top
        height: 28; radius: 14
        width: libText.implicitWidth + 24
        color: libArea.containsMouse ? Theme.clock : Theme.surface
        Text { id: libText; anchors.centerIn: parent; text: Icons.g(0xf1bc) + "  Library"; color: libArea.containsMouse ? Theme.onPill : Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
        MouseArea { id: libArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Fluid.openIsland("spotify", Fluid.islandScreen) }
    }

    // ---- Equalizer -------------------------------------------------------------
    Rectangle {
        anchors.top: player.bottom
        anchors.topMargin: 14
        anchors.bottom: parent.bottom
        width: parent.width
        radius: 16
        color: Theme.surface

        Text {
            x: 14; y: 10
            text: "Equalizer" + (Equalizer.available ? "  ·  " + Equalizer.preset : "")
            color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
        }

        Text {
            anchors.centerIn: parent
            width: parent.width - 40
            visible: !Equalizer.available
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            text: "The equalizer starts with PipeWire. Log out and back in once (or run\nsystemctl --user restart pipewire) after installing."
            color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
        }

        // 10 vertical band sliders, -12..+12 dB
        Row {
            id: bands
            visible: Equalizer.available
            anchors.top: parent.top
            anchors.topMargin: 32
            anchors.horizontalCenter: parent.horizontalCenter
            height: 92
            spacing: (parent.width - 28 - 10 * 22) / 9

            Repeater {
                model: 10
                Item {
                    id: band
                    required property int index
                    readonly property real gain: Equalizer.gains[index]
                    width: 22; height: bands.height

                    Rectangle {
                        id: groove
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 0
                        width: 4; height: parent.height - 16; radius: 2
                        color: Theme.surfaceHi
                        // fill from the 0 dB line to the knob
                        Rectangle {
                            width: parent.width; radius: 2
                            readonly property real zeroY: groove.height / 2
                            readonly property real knobY: groove.height * (0.5 - band.gain / 24)
                            y: Math.min(zeroY, knobY)
                            height: Math.abs(knobY - zeroY)
                            color: Theme.clock
                            Behavior on y { NumberAnimation { duration: Anim.normal } }
                            Behavior on height { NumberAnimation { duration: Anim.normal } }
                        }
                    }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 16; height: 16; radius: 8
                        y: groove.height * (0.5 - band.gain / 24) - height / 2
                        color: Theme.fg
                        border.width: 3
                        border.color: Theme.clock
                        Behavior on y { enabled: !bandDrag.pressed; NumberAnimation { duration: Anim.normal; easing.type: Easing.OutBack } }
                    }
                    Text {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Equalizer.freqs[band.index]
                        color: Theme.fgDim; font.family: Theme.font; font.pixelSize: 9
                    }
                    MouseArea {
                        id: bandDrag
                        anchors.fill: groove
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        function at(my) { Equalizer.setBand(band.index, (0.5 - (my - 8) / groove.height) * 24); }
                        onPressed: m => at(m.y)
                        onPositionChanged: m => { if (pressed) at(m.y); }
                        onDoubleClicked: Equalizer.setBand(band.index, 0)
                        onWheel: w => Equalizer.setBand(band.index, band.gain + (w.angleDelta.y > 0 ? 1 : -1))
                    }
                }
            }
        }

        Flow {
            visible: Equalizer.available
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 28
            spacing: 6
            Repeater {
                model: Equalizer.presetNames
                Rectangle {
                    required property string modelData
                    readonly property bool chosen: Equalizer.preset === modelData
                    height: 26; radius: 13
                    width: pText.implicitWidth + 20
                    color: chosen ? Theme.clock : (pArea.containsMouse ? Theme.surfaceHi : "transparent")
                    border.width: chosen ? 0 : 1
                    border.color: Theme.border
                    Behavior on color { ColorAnimation { duration: Anim.fast } }
                    Text { id: pText; anchors.centerIn: parent; text: parent.modelData; color: parent.chosen ? Theme.onPill : Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
                    MouseArea { id: pArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Equalizer.setPreset(parent.modelData) }
                }
            }
        }
    }
}
