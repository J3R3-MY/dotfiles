import QtQuick
import Quickshell
import "../common"
import "../services"

// cliphist history. Enter copies the selected entry, Shift+Delete removes it.
Item {
    id: root

    readonly property var filtered: {
        const q = search.text.toLowerCase();
        return q.length === 0 ? Clipboard.entries : Clipboard.entries.filter(e => e.text.toLowerCase().includes(q));
    }

    Component.onCompleted: { Clipboard.refresh(); search.focusInput(); }

    function pick(entry) {
        if (!entry) return;
        Clipboard.copy(entry);
        Fluid.closeAll();
    }

    SearchField {
        id: search
        width: parent.width - clearBtn.width - 10
        placeholder: "Search clipboard"
        icon: Icons.clipboard
        onTextChanged: list.currentIndex = 0
        onUp: list.decrementCurrentIndex()
        onDown: list.incrementCurrentIndex()
        onAccepted: root.pick(root.filtered[list.currentIndex])
        onDeleteRequested: {
            const entry = root.filtered[list.currentIndex];
            if (entry) Clipboard.remove(entry);
        }
    }

    Rectangle {
        id: clearBtn
        anchors.right: parent.right
        width: 46; height: 46; radius: 14
        color: clearArea.containsMouse ? Theme.urgent : Theme.surfaceHi
        Behavior on color { ColorAnimation { duration: Anim.fast } }
        Glyph { anchors.centerIn: parent; text: Icons.close }
        MouseArea { id: clearArea; anchors.fill: parent; hoverEnabled: true; onClicked: Clipboard.wipe() }
    }

    ListView {
        id: list
        anchors.top: search.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        spacing: 2
        model: ScriptModel { values: root.filtered; objectProp: "id" }
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: Anim.fast
        highlight: Rectangle { radius: 12; color: Theme.surfaceHi }
        removeDisplaced: Transition { NumberAnimation { property: "y"; duration: Anim.normal; easing.type: Easing.OutCubic } }
        remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Anim.fast } }

        Label {
            anchors.centerIn: parent
            visible: list.count === 0
            text: "Clipboard is empty"
            dim: true; size: "lg"
        }

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            width: list.width
            height: 42

            Label {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                maximumLineCount: 1
                text: row.modelData.image ? "🖼  Image" : row.modelData.text.replace(/\s+/g, " ")
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: list.currentIndex = row.index
                onClicked: root.pick(row.modelData)
            }
        }
    }
}
