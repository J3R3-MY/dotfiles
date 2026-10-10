import QtQuick
import Quickshell
import "../common"
import "../services"

// Spotify library ($mod+Shift+m, or "Library" in the media view).
// Search / Liked / Playlists / Devices. Click or Enter plays; what's playing
// shows in the media view and the island like any other player.
Item {
    id: root

    property string tab: "search"
    readonly property var rows: {
        if (tab === "search") {
            const r = Spotify.results;
            return r.tracks.slice(0, 12).map(t => ({ kind: "track", item: t, title: t.name, sub: Spotify.artists(t), icon: Icons.music }))
                .concat(r.albums.slice(0, 5).map(a => ({ kind: "album", item: a, title: a.name, sub: "Album · " + Spotify.artists(a), icon: Icons.g(0xf0025) })))
                .concat(r.artists.slice(0, 4).map(a => ({ kind: "artist", item: a, title: a.name, sub: "Artist", icon: Icons.g(0xf007) })))
                .concat(r.playlists.slice(0, 5).map(p => ({ kind: "playlist", item: p, title: p.name, sub: "Playlist", icon: Icons.g(0xf0cb8) })));
        }
        if (tab === "liked") return [{ kind: "liked", item: null, title: "Play all liked songs", sub: Spotify.liked.length + " songs", icon: Icons.g(0xf004) }]
            .concat(Spotify.liked.map(t => ({ kind: "track", item: t, title: t.name, sub: Spotify.artists(t), icon: Icons.music })));
        if (tab === "playlists") return Spotify.playlists.map(p => ({ kind: "playlist", item: p, title: p.name, sub: p.owner ? "by " + (Array.isArray(p.owner) ? p.owner[0] : p.owner) : "", icon: Icons.g(0xf0cb8) }));
        return Spotify.devices.map(d => ({ kind: "device", item: d, title: d.name, sub: d.active ? "playing here" : "tap to switch", icon: Icons.g(0xf04c3) }));
    }

    function activate(r) {
        if (!r) return;
        if (r.kind === "track") Spotify.playTrack(r.item);
        else if (r.kind === "liked") Spotify.playLiked();
        else if (r.kind === "device") Spotify.connect(r.item);
        else Spotify.playContext(r.kind, r.item);
    }

    Component.onCompleted: { Spotify.check(); Spotify.loadLibrary(); search.focusInput(); }
    Keys.onEscapePressed: Fluid.closeAll()

    // ---- Not available -----------------------------------------------------------
    Column {
        anchors.centerIn: parent
        spacing: 14
        visible: Spotify.state === "missing" || Spotify.state === "offline"
        z: 2
        Glyph { anchors.horizontalCenter: parent.horizontalCenter; text: Icons.g(0xf1bc); size: 40; color: Theme.clock }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Spotify.state === "missing" ? "spotify_player isn't installed" : "Spotify isn't connected yet"
            color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize
        }
        Rectangle {
            visible: Spotify.state === "offline"
            anchors.horizontalCenter: parent.horizontalCenter
            width: 260; height: 40; radius: 14
            color: Theme.clock
            Text { anchors.centerIn: parent; text: "Sign in (opens a terminal)"; color: Theme.onPill; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Spotify.authenticate() }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Needs Spotify Premium. Re-open this after signing in."
            color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4
        }
    }

    Item {
        anchors.fill: parent
        visible: Spotify.state === "ready" || Spotify.state === "unknown"

        Row {
            id: tabs
            spacing: 6
            Repeater {
                model: [{ id: "search", t: "Search" }, { id: "liked", t: "Liked" }, { id: "playlists", t: "Playlists" }, { id: "devices", t: "Devices" }]
                Chip {
                    required property var modelData
                    text: modelData.t
                    on: root.tab === modelData.id
                    size: Theme.fontSize - 2
                    onClicked: { root.tab = modelData.id; list.currentIndex = 0; }
                }
            }
        }

        SearchField {
            id: search
            anchors.top: tabs.bottom
            anchors.topMargin: 10
            width: parent.width
            visible: root.tab === "search"
            height: visible ? implicitHeight : 0
            placeholder: "Search Spotify"
            icon: Icons.g(0xf1bc)
            onTextChanged: debounce.restart()
            onUp: list.decrementCurrentIndex()
            onDown: list.incrementCurrentIndex()
            onAccepted: root.activate(root.rows[list.currentIndex])
        }
        Timer { id: debounce; interval: 350; onTriggered: Spotify.search(search.text) }

        ListView {
            id: list
            anchors.top: search.bottom
            anchors.topMargin: 10
            anchors.bottom: parent.bottom
            width: parent.width
            clip: true
            spacing: 2
            model: root.rows
            highlightMoveDuration: Anim.fast
            highlight: Rectangle { radius: 12; color: Theme.surfaceHi }
            boundsBehavior: Flickable.StopAtBounds
            Keys.onReturnPressed: root.activate(root.rows[currentIndex])

            delegate: Item {
                id: r
                required property var modelData
                required property int index
                width: list.width
                height: 46
                Glyph { id: ri; x: 14; anchors.verticalCenter: parent.verticalCenter; text: r.modelData.icon; color: Theme.clock }
                Column {
                    anchors.left: ri.right; anchors.leftMargin: 14
                    anchors.right: parent.right; anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    Text { width: parent.width; elide: Text.ElideRight; text: r.modelData.title; color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
                    Text { width: parent.width; elide: Text.ElideRight; visible: text.length > 0; text: r.modelData.sub; color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4 }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: list.currentIndex = r.index
                    onClicked: root.activate(r.modelData)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: list.count === 0
                text: Spotify.loading ? "Searching…" : root.tab === "search" ? "Type to search songs, albums, artists and playlists" : "Nothing here yet"
                color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
            }
        }
    }
}
