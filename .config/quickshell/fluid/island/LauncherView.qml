import QtQuick
import Quickshell
import Quickshell.Widgets
import "../common"
import "../services"

// Launcher ($mod+p, Spotlight-style): apps, then files and folders from your
// home (services/Files.qml) once you type two letters. Arrows/Tab move,
// Enter launches / opens, Shift+Enter shows a file in Thunar, Ctrl+Enter
// copies its path, Esc closes.
Item {
    id: root

    readonly property var apps: Apps.search(search.text)
    // Apps first (fewer once files show up), then files
    readonly property var results: {
        const files = search.text.trim().length >= 2 ? Files.results : [];
        return apps.slice(0, files.length ? 6 : 60).map(a => ({ app: a }))
            .concat(files.map(f => ({ file: f })));
    }

    Component.onCompleted: { Files.search(""); search.focusInput(); }

    function activate(r) {
        if (!r) return;
        if (r.app) Apps.launch(r.app); else Files.open(r.file);
        Fluid.closeAll();
    }
    // Files only: Shift+Enter reveals in Thunar, Ctrl+Enter copies the path
    function alternate(r, mods) {
        if (!r || !r.file) return;
        if (mods & Qt.ControlModifier) Files.copyPath(r.file); else Files.reveal(r.file);
        Fluid.closeAll();
    }

    // icon for a file: folder, or a guess from the extension
    function fileIcon(f) {
        if (f.isDir) return "folder";
        const ext = f.name.includes(".") ? f.name.split(".").pop().toLowerCase() : "";
        const kinds = { image: ["png", "jpg", "jpeg", "gif", "webp", "svg"], video: ["mp4", "mkv", "webm", "mov"],
                        audio: ["mp3", "flac", "ogg", "wav", "m4a"], pdf: ["pdf"], code: ["sh", "py", "js", "qml", "lua", "c", "cpp", "rs", "go", "ts"] };
        const names = { image: "image-x-generic", video: "video-x-generic", audio: "audio-x-generic", pdf: "application-pdf", code: "text-x-script" };
        for (const k in kinds) if (kinds[k].indexOf(ext) >= 0) return names[k];
        return "text-x-generic";
    }

    SearchField {
        id: search
        width: parent.width
        placeholder: "Search apps and files"
        onTextChanged: { list.currentIndex = 0; Files.search(text); }
        onUp: list.decrementCurrentIndex()
        onDown: list.incrementCurrentIndex()
        onAccepted: root.activate(root.results[list.currentIndex])
        onShortcut: (key, mods) => { if (key === Qt.Key_Return) root.alternate(root.results[list.currentIndex], mods); }
    }

    ListView {
        id: list
        anchors.top: search.bottom
        anchors.topMargin: 10
        anchors.bottom: hint.top
        anchors.bottomMargin: 6
        width: parent.width
        clip: true
        spacing: 2
        model: ScriptModel { values: root.results }
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
            readonly property var app: modelData.app || null
            readonly property var file: modelData.file || null
            width: list.width
            height: 50

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                spacing: 14

                IconImage {
                    implicitSize: 32
                    anchors.verticalCenter: parent.verticalCenter
                    source: row.app ? Quickshell.iconPath(row.app.icon, "application-x-executable")
                                    : Quickshell.iconPath(root.fileIcon(row.file), "text-x-generic")
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: row.width - 70
                    Label {
                        width: parent.width; elide: Text.ElideRight
                        text: row.app ? row.app.name : row.file.name
                        size: "lg"
                    }
                    Label {
                        width: parent.width; elide: Text.ElideMiddle
                        visible: text.length > 0
                        text: row.app ? (row.app.comment || row.app.genericName || "") : row.file.dir
                        dim: true; size: "sm"
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onEntered: list.currentIndex = row.index
                // right-click a file: show it in Thunar
                onClicked: m => m.button === Qt.RightButton ? root.alternate(row.modelData, 0) : root.activate(row.modelData)
            }
        }
    }

    Label {
        id: hint
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        visible: !!(root.results[list.currentIndex] && root.results[list.currentIndex].file)
        text: "Enter open  ·  Shift+Enter show in Thunar  ·  Ctrl+Enter copy path"
        dim: true; size: "xs"
    }
}
