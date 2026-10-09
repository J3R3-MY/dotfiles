import QtQuick
import Quickshell
import Quickshell.Widgets
import "../common"
import "../services"

// Theme selector ($mod+t). A carousel of slanted wallpaper cards (the focused
// one widens), colour dots to filter wallpapers by colour, and the palette
// tweaks underneath. Picking a wallpaper recolours the desktop via matugen.
//   ←/→ or scroll   move through wallpapers      Enter/click   apply
Item {
    id: root

    property string colorFilter: ""
    readonly property var shown: colorFilter ? Wallpaper.files.filter(f => Wallpaper.bucket(f) === colorFilter) : Wallpaper.files

    Keys.onEscapePressed: Fluid.closeAll()
    Keys.onLeftPressed: carousel.decrementCurrentIndex()
    Keys.onRightPressed: carousel.incrementCurrentIndex()
    Keys.onReturnPressed: if (shown[carousel.currentIndex]) Wallpaper.apply(shown[carousel.currentIndex])
    Component.onCompleted: {
        Wallpaper.rescan();
        if (Wallpaper.sourceColors.length === 0) Wallpaper.probeSources();
        forceActiveFocus();
    }

    // ---- Top: title, colour filter, live palette ------------------------------
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

        // Colour filter dots ("all" + 8 colours), like the reference picker
        Rectangle {
            anchors.centerIn: parent
            height: 36; radius: 18
            width: filterRow.implicitWidth + 16
            color: Theme.surface
            Row {
                id: filterRow
                anchors.centerIn: parent
                spacing: 6
                Rectangle {
                    width: 26; height: 26; radius: 8
                    color: root.colorFilter === "" ? Theme.clock : Theme.surfaceHi
                    Glyph { anchors.centerIn: parent; text: Icons.g(0xf00a); size: 12; color: root.colorFilter === "" ? Theme.onPill : Theme.fg }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.colorFilter = "" }
                }
                Repeater {
                    model: Wallpaper.colorFilters
                    Rectangle {
                        required property var modelData
                        readonly property bool on: root.colorFilter === modelData.id
                        width: 26; height: 26; radius: 8
                        color: modelData.color
                        border.width: on ? 2 : 0
                        border.color: Theme.fg
                        scale: on ? 1.15 : (fArea.containsMouse ? 1.08 : 1)
                        Behavior on scale { NumberAnimation { duration: Anim.fast; easing.type: Easing.OutBack } }
                        MouseArea { id: fArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.colorFilter = parent.on ? "" : parent.modelData.id }
                    }
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Repeater {
                model: [Theme.clock, Theme.battery, Theme.cpu, Theme.memory, Theme.backlight, Theme.network, Theme.audio, Theme.bg, Theme.fg]
                Rectangle {
                    required property color modelData
                    width: 16; height: 16; radius: 8
                    color: modelData
                    border.width: 1
                    border.color: Theme.border
                }
            }
        }
    }

    // ---- Carousel ---------------------------------------------------------------
    ListView {
        id: carousel
        anchors.top: topRow.bottom
        anchors.topMargin: 16
        width: parent.width
        height: 280
        orientation: ListView.Horizontal
        spacing: -18                         // slanted cards overlap a little
        clip: true
        model: root.shown
        currentIndex: Math.max(0, root.shown.indexOf(Wallpaper.current))
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: width / 2 - 230
        preferredHighlightEnd: width / 2 + 230
        highlightMoveDuration: Anim.slow
        boundsBehavior: Flickable.StopAtBounds

        WheelHandler {
            onWheel: e => {
                if ((e.angleDelta.y || e.angleDelta.x) < 0) carousel.incrementCurrentIndex();
                else carousel.decrementCurrentIndex();
            }
        }

        delegate: Item {
            id: card
            required property string modelData
            required property int index
            readonly property bool focused: ListView.isCurrentItem
            readonly property bool isCurrent: modelData === Wallpaper.current

            width: focused ? 460 : 150
            height: carousel.height
            z: focused ? 2 : 1
            Behavior on width { NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } }

            // Shear along x so every card is a parallelogram
            ClippingRectangle {
                anchors.fill: parent
                anchors.topMargin: card.focused ? 0 : 18
                anchors.bottomMargin: card.focused ? 0 : 18
                radius: 10
                color: Theme.surfaceHi
                transform: Matrix4x4 {
                    matrix: Qt.matrix4x4(1, -0.2, 0, 0.2 * card.height / 2,
                                         0, 1, 0, 0,
                                         0, 0, 1, 0,
                                         0, 0, 0, 1)
                }
                Behavior on anchors.topMargin { NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } }
                Behavior on anchors.bottomMargin { NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } }

                Image {
                    anchors.centerIn: parent
                    // wider than the card so the shear never shows an edge
                    width: 520; height: parent.height
                    source: "file://" + card.modelData
                    sourceSize.width: 640
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    opacity: status === Image.Ready ? (card.focused ? 1 : 0.75) : 0
                    Behavior on opacity { NumberAnimation { duration: Anim.normal } }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: "transparent"
                    border.width: card.isCurrent ? 3 : (card.focused ? 2 : 0)
                    border.color: card.isCurrent ? Theme.clock : Theme.fg
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!card.focused) carousel.currentIndex = card.index;
                    else Wallpaper.apply(card.modelData);
                }
                onDoubleClicked: Wallpaper.apply(card.modelData)
            }
        }

        Text {
            anchors.centerIn: parent
            visible: root.shown.length === 0
            text: root.colorFilter ? "No wallpapers in this colour" : "No wallpapers found in ~/.config/wallpapers"
            color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize
        }
    }

    // ---- Tweaks -------------------------------------------------------------------
    Rectangle {
        anchors.top: carousel.bottom
        anchors.topMargin: 16
        anchors.bottom: parent.bottom
        width: parent.width
        radius: 16
        color: Theme.surface

        Row {
            id: tweaks
            anchors.fill: parent
            anchors.margins: 16
            spacing: 24
            readonly property real colW: (width - 48) / 3

            // Column 1: mode + base colour
            Column {
                width: tweaks.colW
                spacing: 14

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

                Column {
                    width: parent.width
                    spacing: 6
                    Text { text: "Base colour from the wallpaper"; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3 }
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
                        Text {
                            visible: Wallpaper.sourceColors.length === 0
                            text: "…"
                            color: Theme.fgDim; font.pixelSize: Theme.fontSize
                        }
                    }
                }
            }

            // Column 2: sliders
            Column {
                width: tweaks.colW
                spacing: 10
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
                TweakSlider {
                    width: parent.width
                    label: "Contrast"
                    from: -1; to: 1; step: 0.1; decimals: 1
                    value: Wallpaper.contrast
                    onMoved: v => { Wallpaper.contrast = v; Wallpaper.retheme(); }
                }
                TweakSlider {
                    width: parent.width
                    label: "Brightness"
                    from: -0.3; to: 0.3; step: 0.05; decimals: 2
                    value: Wallpaper.lightness
                    onMoved: v => { Wallpaper.lightness = v; Wallpaper.retheme(); }
                }
            }

            // Column 3: style + shuffle/reset
            Column {
                width: tweaks.colW
                spacing: 10
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
                            width: (tweaks.colW - 8) / 2; height: 34; radius: 12
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
            }
        }
    }
}
