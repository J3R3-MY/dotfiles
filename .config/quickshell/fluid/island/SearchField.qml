import QtQuick
import "../common"

// Rounded search input shared by launcher and clipboard views.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: "Search"
    property string icon: Icons.search
    signal accepted()
    signal up()
    signal down()
    signal deleteRequested()   // Shift+Delete

    implicitHeight: 46
    radius: 14
    color: Theme.surfaceHi

    function focusInput() { input.forceActiveFocus(); }

    Glyph {
        id: glyph
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: Theme.fgDim
    }

    TextInput {
        id: input
        anchors.left: glyph.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.fg
        selectionColor: Theme.accent
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 2
        focus: true
        clip: true

        Keys.onEscapePressed: Fluid.closeAll()
        Keys.onReturnPressed: root.accepted()
        Keys.onEnterPressed: root.accepted()
        Keys.onUpPressed: root.up()
        Keys.onDownPressed: root.down()
        Keys.onTabPressed: root.down()
        Keys.onBacktabPressed: root.up()
        Keys.onDeletePressed: e => {
            if (e.modifiers & Qt.ShiftModifier) { root.deleteRequested(); e.accepted = true; }
            else e.accepted = false;
        }

        Text {
            visible: input.text.length === 0
            text: root.placeholder
            color: Theme.fgDim
            font: input.font
        }
    }
}
