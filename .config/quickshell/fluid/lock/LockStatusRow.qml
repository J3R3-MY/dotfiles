import QtQuick
import "../common"
import "../services"

// Battery · network · weather line used at the bottom of the lock designs.
Row {
    spacing: 24
    opacity: 0.85
    Repeater {
        model: [
            Battery.available ? Icons.battery(Battery.percent, Battery.charging) + "  " + Battery.percent + "%" : "",
            Network.connected ? (Network.type === "ethernet" ? Icons.ethernet : Icons.wifi) + "  " + Network.name : "",
            Weather.ready ? Weather.icon + "  " + Math.round(Weather.temp) + "°" : ""
        ].filter(t => t)
        Label {
            required property string modelData
            text: modelData
            color: "white"; size: "lg"
        }
    }
}
