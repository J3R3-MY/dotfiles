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
    signal shortcut(int key, int modifiers)   // Shift+Enter, Ctrl+<letter>

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
        Keys.onReturnPressed: e => (e.modifiers & Qt.ShiftModifier) ? root.shortcut(Qt.Key_Return, e.modifiers) : root.accepted()
        Keys.onEnterPressed: e => (e.modifiers & Qt.ShiftModifier) ? root.shortcut(Qt.Key_Return, e.modifiers) : root.accepted()
        Keys.onPressed: e => {
            // Ctrl+letter shortcuts, leaving the usual editing keys alone
            const editing = [Qt.Key_A, Qt.Key_C, Qt.Key_V, Qt.Key_X, Qt.Key_Z, Qt.Key_Y];
            if ((e.modifiers & Qt.ControlModifier) && e.key >= Qt.Key_A && e.key <= Qt.Key_Z && editing.indexOf(e.key) < 0) {
                root.shortcut(e.key, e.modifiers);
                e.accepted = true;
            }
        }
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
