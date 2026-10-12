import QtQuick
import QtQuick.Effects

// The lock design, shared by the lock screen (LockClassic.qml) and the SDDM
// login theme (sddm/fluid/Main.qml): blurred wallpaper, centred clock that
// slides up when authMode turns on, then the key ring around the avatar, the
// user name and a hint. Children go in the row at the bottom.
// No fluid imports: install/lib.sh copies this file into the SDDM theme too.
Item {
    id: root

    property string wallpaper: ""
    property string face: ""             // avatar image, else the initial
    property bool authMode: false
    property string user: ""
    property int length: 0               // password length, for the key ring
    property bool busy: false
    property string status: ""           // error text, shown until typing again
    property string hint: "Enter password"

    property color accent: "#c4bca4"
    property color ink: "#0e0c0c"
    property color dim: "#a7a097"
    property color bg: "#0e0c0c"
    property string font: "Roboto"
    property int fontSize: 15

    default property alias footer: foot.data
    function shake() { ring.shake(); }

    // Anim.slow / Anim.normal / Anim.emphasized (common/Anim.qml)
    readonly property list<real> curve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]

    Image {
        id: wp
        anchors.fill: parent
        source: root.wallpaper
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: Math.max(640, root.width / 2)
        asynchronous: true
        visible: false
    }
    Rectangle { anchors.fill: parent; color: root.bg; visible: wp.status !== Image.Ready }
    MultiEffect {
        anchors.fill: parent
        source: wp
        visible: wp.status === Image.Ready
        blurEnabled: true
        blurMax: 64
        blur: root.authMode ? 1.0 : 0.6
        brightness: root.authMode ? -0.25 : -0.1
        Behavior on blur { NumberAnimation { duration: 480 } }
        Behavior on brightness { NumberAnimation { duration: 480 } }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.authMode ? parent.height * 0.18 : parent.height * 0.5 - height / 2
        scale: root.authMode ? 0.6 : 1
        Behavior on y { NumberAnimation { duration: 480; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve } }
        Behavior on scale { NumberAnimation { duration: 480; easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve } }
        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: "white"; font.family: "JetBrains Mono"; font.pixelSize: 140; font.weight: Font.Bold
        }
        Text {
            id: date
            anchors.horizontalCenter: parent.horizontalCenter
            color: Qt.rgba(1, 1, 1, 0.8); font.family: root.font; font.pixelSize: 22
        }
        Timer {
            interval: 1000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: { const d = new Date(); clock.text = Qt.formatTime(d, "HH:mm"); date.text = Qt.formatDate(d, "dddd, d MMMM"); }
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.55
        spacing: 18
        opacity: root.authMode ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 320 } }
        KeyRing {
            id: ring
            anchors.horizontalCenter: parent.horizontalCenter
            accent: root.accent; dim: root.dim
            length: root.length
            busy: root.busy
            error: root.status !== "" && root.length === 0
            Avatar {
                anchors.centerIn: parent
                user: root.user; source: root.face
                color: root.accent; ink: root.ink; font: root.font
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.user
            color: "white"; font.family: root.font; font.pixelSize: 18; font.weight: Font.DemiBold
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.busy ? "Checking…" : (ring.error ? root.status : root.hint)
            color: ring.error ? ring.errorColor : Qt.rgba(1, 1, 1, 0.6)
            font.family: root.font; font.pixelSize: root.fontSize
        }
    }

    Row {
        id: foot
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        spacing: 24
    }
}
