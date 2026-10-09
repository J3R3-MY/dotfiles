import QtQuick
import Quickshell
import Quickshell.Wayland
import "../common"
import "../services"

// Wallpaper with a crossfade + slight zoom when it changes.
// fluid-theme.sh also points swaybg at the same image, so the wallpaper is
// still there if the shell isn't running.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "fluid-wallpaper"

    property bool useA: true
    property Item pending: null
    readonly property string source: Wallpaper.current ? "file://" + Wallpaper.current : ""
    onSourceChanged: load()

    function load() {
        if (!source) return;
        pending = useA && imgA.opacity > 0 ? imgB : imgA;
        // Reset first so going back to a previously shown image still
        // emits a status change
        pending.source = "";
        pending.source = source;
    }

    component Layer: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: win.width
        sourceSize.height: win.height
        opacity: 0
        scale: 1.04
        Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutQuad } }
        Behavior on scale { NumberAnimation { duration: 1200; easing.type: Easing.OutCubic } }
    }

    Layer {
        id: imgA
        z: win.useA ? 1 : 0
        onStatusChanged: if (status === Image.Ready && win.pending === imgA) { win.pending = null; win.useA = true; opacity = 1; scale = 1; imgB.opacity = 0; imgB.scale = 1.04; }
    }
    Layer {
        id: imgB
        z: win.useA ? 0 : 1
        onStatusChanged: if (status === Image.Ready && win.pending === imgB) { win.pending = null; win.useA = false; opacity = 1; scale = 1; imgA.opacity = 0; imgA.scale = 1.04; }
    }

    Component.onCompleted: load()
}
