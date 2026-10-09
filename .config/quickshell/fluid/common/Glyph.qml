import QtQuick
import "."

// Icon text. Fontconfig falls back to the Nerd Font for the private-use glyphs.
Text {
    property int size: Theme.fontSize + 1
    color: Theme.fg
    font.family: "Symbols Nerd Font"
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
