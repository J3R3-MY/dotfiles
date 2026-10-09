import QtQuick
import Quickshell
import Quickshell.Widgets
import "../common"
import "../services"

// Theme selector: pick a wallpaper and the whole desktop is recoloured from it
// (matugen); the panel on the right fine-tunes the generated palette live.
// Arrow keys + Enter work in the grid.
Item {
    id: root

    Keys.onEscapePressed: Fluid.closeAll()
    Keys.onLeftPressed: grid.moveCurrentIndexLeft()
    Keys.onRightPressed: grid.moveCurrentIndexRight()
    Keys.onUpPressed: grid.moveCurrentIndexUp()
    Keys.onDownPressed: grid.moveCurrentIndexDown()
    Keys.onReturnPressed: Wallpaper.apply(Wallpaper.files[grid.currentIndex])
    Component.onCompleted: {
        Wallpaper.rescan();
        if (Wallpaper.sourceColors.length === 0) Wallpaper.probeSources();
        forceActiveFocus();
    }

    // ---- Header --------------------------------------------------------------
    Item {
        id: topRow
        width: parent.width
        height: 36

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Glyph { text: Icons.palette; color: Theme.clock; size: 20; anchors.verticalCenter: parent.verticalCenter }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Wallpaper & theme"
                color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize + 1; font.weight: Font.DemiBold
            }
            // Small spinner dot while matugen runs
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 8; height: 8; radius: 4
                color: Theme.clock
                opacity: Wallpaper.busy ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Anim.fast } }
                SequentialAnimation on scale {
                    running: Wallpaper.busy
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.6; duration: 300 }
                    NumberAnimation { to: 1.0; duration: 300 }
                }
            }
        }

        // Live palette preview: the bar colours as they are right now
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Repeater {
                model: [Theme.clock, Theme.battery, Theme.cpu, Theme.memory, Theme.backlight, Theme.network, Theme.audio, Theme.accent, Theme.bg, Theme.fg]
                Rectangle {
                    required property color modelData
                    width: 18; height: 18; radius: 9
                    color: modelData
                    border.width: 1
                    border.color: Theme.border
                }
            }
        }
    }

    // ---- Wallpaper grid -------------------------------------------------------
    GridView {
        id: grid
        anchors.top: topRow.bottom
        anchors.topMargin: 12
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: panel.left
        anchors.rightMargin: 14
        clip: true
        cellWidth: width / 3
        cellHeight: cellWidth * 0.62
        boundsBehavior: Flickable.StopAtBounds
        model: Wallpaper.files
        currentIndex: Math.max(0, Wallpaper.files.indexOf(Wallpaper.current))

        delegate: Item {
            id: cell
            required property string modelData
            required property int index
            readonly property bool isCurrent: modelData === Wallpaper.current
            readonly property bool isSelected: GridView.isCurrentItem
            width: grid.cellWidth
            height: grid.cellHeight

            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: 6
                radius: 12
                color: Theme.surfaceHi
                scale: thumbArea.containsMouse || cell.isSelected ? 1.0 : 0.95
                Behavior on scale { NumberAnimation { duration: Anim.normal; easing.type: Easing.OutBack } }

                Image {
                    anchors.fill: parent
                    source: "file://" + cell.modelData
                    sourceSize.width: 360
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Anim.normal } }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: "transparent"
                    border.width: cell.isCurrent ? 3 : (cell.isSelected ? 2 : 0)
                    border.color: cell.isCurrent ? Theme.clock : Theme.fg
                    Behavior on border.width { NumberAnimation { duration: Anim.fast } }
                }
            }

            MouseArea {
                id: thumbArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { grid.currentIndex = cell.index; Wallpaper.apply(cell.modelData); }
            }
        }
    }

    // ---- Tweak panel ----------------------------------------------------------
    Rectangle {
        id: panel
        anchors.top: topRow.bottom
        anchors.topMargin: 12
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 300
        radius: 16
        color: Theme.surface

        Flickable {
            anchors.fill: parent
            anchors.margins: 14
            contentHeight: col.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: col
                width: parent.width
                spacing: 14

                // Dark / light
                Rectangle {
                    id: seg
                    width: parent.width; height: 32; radius: 16
                    color: Theme.surfaceHi
                    Rectangle {
                        width: parent.width / 2 - 4; height: parent.height - 6; radius: height / 2
                        y: 3
                        x: Wallpaper.mode === "dark" ? 3 : parent.width / 2 + 1
                        color: Theme.clock
                        Behavior on x { NumberAnimation { duration: Anim.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.spring } }
                    }
                    Row {
                        anchors.fill: parent
                        Repeater {
                            model: [{ m: "dark", t: Icons.moon + "  Dark" }, { m: "light", t: Icons.sun + "  Light" }]
                            Item {
                                required property var modelData
                                width: seg.width / 2; height: seg.height
                                Text {
                                    anchors.centerIn: parent
                                    text: parent.modelData.t
                                    color: Wallpaper.mode === parent.modelData.m ? Theme.onPill : Theme.fg
                                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Wallpaper.setMode(parent.modelData.m) }
                            }
                        }
                    }
                }

                // Which wallpaper colour seeds the palette
                Column {
                    width: parent.width
                    spacing: 6
                    visible: Wallpaper.sourceColors.length > 0
                    Text { text: "Base colour"; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
                    Row {
                        spacing: 8
                        Repeater {
                            model: Wallpaper.sourceColors
                            Rectangle {
                                required property string modelData
                                required property int index
                                readonly property bool chosen: index === Wallpaper.sourceIndex
                                width: 34; height: 34; radius: 17
                                color: modelData
                                border.width: chosen ? 3 : 1
                                border.color: chosen ? Theme.fg : Theme.border
                                scale: chosen ? 1.1 : 1
                                Behavior on scale { NumberAnimation { duration: Anim.normal; easing.type: Easing.OutBack } }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { Wallpaper.sourceIndex = parent.index; Wallpaper.retheme(); }
                                }
                            }
                        }
                    }
                }

                TweakSlider {
                    width: parent.width
                    label: "Hue shift"
                    from: -180; to: 180; step: 5; decimals: 0; suffix: "°"
                    value: Wallpaper.hueShift
                    hueTrack: true
                    baseHue: {
                        const c = Qt.lighter(Wallpaper.sourceColors[Wallpaper.sourceIndex] || "#888888", 1.0);
                        return c.hslHue < 0 ? 0 : c.hslHue;
                    }
                    onMoved: v => { Wallpaper.hueShift = v; Wallpaper.retheme(); }
                }

                // Palette style, calm -> loud
                Column {
                    width: parent.width
                    spacing: 6
                    Text { text: "Style"; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
                    Flow {
                        width: parent.width
                        spacing: 6
                        Repeater {
                            model: Wallpaper.schemes
                            Rectangle {
                                required property var modelData
                                readonly property bool chosen: Wallpaper.scheme === modelData.id
                                height: 28; radius: 14
                                width: chipText.implicitWidth + 22
                                color: chosen ? Theme.clock : (chipArea.containsMouse ? Theme.surfaceHi : "transparent")
                                border.width: chosen ? 0 : 1
                                border.color: Theme.border
                                Behavior on color { ColorAnimation { duration: Anim.fast } }
                                Text {
                                    id: chipText
                                    anchors.centerIn: parent
                                    text: parent.modelData.label
                                    color: parent.chosen ? Theme.onPill : Theme.fg
                                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                                }
                                MouseArea {
                                    id: chipArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { Wallpaper.scheme = parent.modelData.id; Wallpaper.retheme(); }
                                }
                            }
                        }
                    }
                }

                TweakSlider {
                    width: parent.width
                    label: "Contrast"
                    from: -1; to: 1; step: 0.1; decimals: 1
                    value: Wallpaper.contrast
                    onMoved: v => { Wallpaper.contrast = v; Wallpaper.retheme(); }
                }

                TweakSlider {
                    width: parent.width
                    label: Wallpaper.mode === "dark" ? "Brightness (dark)" : "Brightness (light)"
                    from: -0.3; to: 0.3; step: 0.05; decimals: 2
                    value: Wallpaper.lightness
                    onMoved: v => { Wallpaper.lightness = v; Wallpaper.retheme(); }
                }

                Row {
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: [
                            { t: "🎲  Shuffle", f: () => Wallpaper.shuffle() },
                            { t: "↺  Reset", f: () => Wallpaper.reset() }
                        ]
                        Rectangle {
                            required property var modelData
                            width: (col.width - 8) / 2; height: 36; radius: 12
                            color: btnArea.containsMouse ? Theme.surfaceHi : Theme.bg
                            border.width: 1
                            border.color: Theme.border
                            scale: btnArea.pressed ? 0.95 : 1
                            Behavior on scale { NumberAnimation { duration: Anim.fast; easing.type: Easing.OutBack } }
                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData.t
                                color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                            }
                            MouseArea { id: btnArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData.f() }
                        }
                    }
                }

                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: "Double-click a slider to reset it. Tweaks are kept when you switch wallpapers; the base colour and hue reset."
                    color: Theme.fgDim; opacity: 0.8
                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 5
                }
            }
        }
    }
}
