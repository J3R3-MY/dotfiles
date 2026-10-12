import QtQuick
import "."

// Text in the shell's font and type scale.
//   size: "xs" | "sm" | "md" (default) | "lg"     dim: secondary colour
// For anything bigger (clocks, temperatures) set font.pixelSize directly.
Text {
    property string size: "md"
    property bool dim: false
    color: dim ? Theme.fgDim : Theme.fg
    font.family: Theme.font
    font.pixelSize: Theme.fontSize + ({ xs: -4, sm: -3, md: -1, lg: 0 })[size]
}
