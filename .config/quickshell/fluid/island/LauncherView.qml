import QtQuick
import Quickshell
import Quickshell.Widgets
import "../common"
import "../services"

// App launcher (Spotlight-style). Type to filter, arrows/Tab to move,
// Enter to launch, Esc to close.
Item {
    id: root

    property var results: Apps.search(search.text)

    Component.onCompleted: search.focusInput()

    SearchField {
        id: search
        width: parent.width
        placeholder: "Search apps"
        onTextChanged: list.currentIndex = 0
        onUp: list.decrementCurrentIndex()
        onDown: list.incrementCurrentIndex()
        onAccepted: {
            const app = root.results[list.currentIndex];
            if (app) { Apps.launch(app); Fluid.closeAll(); }
        }
    }

    ListView {
        id: list
        anchors.top: search.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        spacing: 2
        model: ScriptModel { values: root.results.slice(0, 60) }
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: Anim.fast
        highlightResizeDuration: 0
        highlight: Rectangle { radius: 12; color: Theme.surfaceHi }

        // Rows slide up into place as the result set changes
        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Anim.fast }
            NumberAnimation { property: "y"; from: 20; duration: Anim.normal; easing.type: Easing.OutCubic }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: Anim.normal; easing.type: Easing.OutCubic }
        }

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            width: list.width
            height: 50

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                spacing: 14

                IconImage {
                    implicitSize: 32
                    anchors.verticalCenter: parent.verticalCenter
                    source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: row.width - 70
                    Text {
                        width: parent.width; elide: Text.ElideRight
                        text: row.modelData.name
                        color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize
                    }
                    Text {
                        width: parent.width; elide: Text.ElideRight
                        visible: text.length > 0
                        text: row.modelData.comment || row.modelData.genericName || ""
                        color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: list.currentIndex = row.index
                onClicked: { Apps.launch(row.modelData); Fluid.closeAll(); }
            }
        }
    }
}
