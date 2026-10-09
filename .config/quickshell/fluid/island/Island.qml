import QtQuick
import Quickshell
import Quickshell.Widgets
import "../common"
import "../services"

// The dynamic island: sits where the waybar clock was and morphs.
//   rest   – clock pill in the old clock colour (+ a "live" equaliser if music plays)
//   hover  – grows; with music playing it shows the track and a play/pause button
//   open   – morphs into launcher / clipboard / media / calendar / theme
//
// Size and colour are bound to the state and animated with a slightly
// overshooting spring, so every transition is one continuous shape change.
Item {
    id: island

    required property string screenName
    readonly property string view: Fluid.islandScreen === screenName ? Fluid.islandView : ""
    readonly property bool open: view !== ""
    readonly property bool hovered: hover.hovered && !open
    readonly property bool mediaHover: hovered && Media.active

    // Keeps the last view loaded while the shape collapses, so content can
    // fade out instead of vanishing.
    property string shownView: ""
    onViewChanged: {
        if (view) { collapseTimer.stop(); shownView = view; }
        else collapseTimer.restart();
    }
    Timer { id: collapseTimer; interval: Anim.normal; onTriggered: island.shownView = "" }

    readonly property var viewSizes: ({
        "launcher": Qt.size(600, 480),
        "clipboard": Qt.size(600, 480),
        "media": Qt.size(560, 440),
        "calendar": Qt.size(1120, 620),
        "theme": Qt.size(1180, 600),
        "keys": Qt.size(1040, 640),
        "spotify": Qt.size(720, 560),
        "vault": Qt.size(680, 520),
        "lockstyle": Qt.size(980, 700)
    })
    readonly property real restWidth: restRow.implicitWidth + 26
    readonly property size targetSize: open ? viewSizes[view]
        : mediaHover ? Qt.size(Math.max(restWidth + 40, 380), 52)
        : hovered ? Qt.size(restWidth + 14, Theme.pillHeight + 4)
        : Qt.size(restWidth, Theme.pillHeight)

    width: targetSize.width
    height: targetSize.height
    Behavior on width { NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.spring } }
    Behavior on height { NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.spring } }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: island.open ? Theme.panelRadius : (island.mediaHover ? 18 : Theme.pillRadius)
        color: island.open || island.mediaHover ? Theme.bg : Theme.clock
        border.width: island.open ? 2 : 0
        border.color: Theme.border
        Behavior on radius { NumberAnimation { duration: Anim.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Anim.emphasized } }
        Behavior on color { ColorAnimation { duration: Anim.normal } }
    }

    HoverHandler { id: hover }

    // ---- Rest face: the clock ------------------------------------------------
    Row {
        id: restRow
        anchors.centerIn: parent
        spacing: 8
        opacity: island.open || island.mediaHover ? 0 : 1
        scale: island.open ? 0.8 : 1
        Behavior on opacity { NumberAnimation { duration: Anim.fast } }
        Behavior on scale { NumberAnimation { duration: Anim.normal } }

        // "Live activity": tiny bouncing bars while something is playing
        Row {
            visible: Media.playing
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
                model: 3
                Rectangle {
                    required property int index
                    width: 3
                    radius: 1.5
                    color: Theme.onPill
                    anchors.verticalCenter: parent.verticalCenter
                    height: 6
                    SequentialAnimation on height {
                        running: Media.playing
                        loops: Animation.Infinite
                        NumberAnimation { to: 14; duration: 260 + index * 90; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 5; duration: 300 + index * 70; easing.type: Easing.InOutSine }
                    }
                }
            }
        }

        Glyph {
            text: Icons.clock
            color: Theme.onPill
            anchors.verticalCenter: parent.verticalCenter
        }
        // Same format as the old waybar clock: "%a, %d %b %H : %M"
        Text {
            text: Qt.formatDateTime(clock.date, "ddd, dd MMM HH : mm")
            color: Theme.onPill
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ---- Hover face: now playing --------------------------------------------
    Row {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10
        opacity: island.mediaHover ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Anim.normal } }

        ClippingRectangle {
            width: 36; height: 36
            radius: 10
            color: Theme.surfaceHi
            anchors.verticalCenter: parent.verticalCenter
            Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true }
        }
        Column {
            width: parent.width - 36 - 40 - 20
            anchors.verticalCenter: parent.verticalCenter
            Text {
                width: parent.width; elide: Text.ElideRight
                text: Media.title
                color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; font.weight: Font.DemiBold
            }
            Text {
                width: parent.width; elide: Text.ElideRight
                text: Media.artist
                color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
            }
        }
        Rectangle {
            width: 34; height: 34; radius: 17
            color: Theme.clock
            anchors.verticalCenter: parent.verticalCenter
            Glyph { anchors.centerIn: parent; text: Media.playing ? Icons.pause : Icons.play; color: Theme.onPill }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Media.toggle() }
        }
    }

    // Click handling for rest/hover states (sits below the hover play button)
    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: !island.open
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => {
            if (Media.active && (island.mediaHover || m.button === Qt.RightButton))
                Fluid.openIsland("media", island.screenName);
            else
                Fluid.openIsland("calendar", island.screenName);
        }
    }

    // ---- Expanded views -----------------------------------------------------
    Loader {
        id: viewLoader
        anchors.fill: parent
        anchors.margins: 14
        active: island.shownView !== ""
        opacity: island.open ? 1 : 0
        // Fade in once the shape has mostly finished morphing
        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: island.open ? 120 : 0 }
                NumberAnimation { duration: Anim.fast }
            }
        }
        readonly property var files: ({ launcher: "LauncherView.qml", clipboard: "ClipboardView.qml", media: "MediaView.qml",
                                         calendar: "DashboardView.qml", theme: "ThemeView.qml", keys: "KeysView.qml",
                                         spotify: "SpotifyView.qml", vault: "VaultView.qml", lockstyle: "LockStyleView.qml" })
        source: island.shownView ? files[island.shownView] : ""
    }
}
