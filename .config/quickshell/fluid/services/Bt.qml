pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: !!adapter
    readonly property bool enabled: available && adapter.enabled
    readonly property var devices: available ? adapter.devices.values : []
    readonly property var connected: devices.filter(d => d.connected)

    // Same text the waybar module showed: alias (+ battery) when connected
    readonly property string label: {
        if (!available) return "off";
        if (!enabled) return "off";
        if (connected.length === 0) return "on";
        const d = connected[0];
        return d.batteryAvailable ? `${d.name} ${Math.round(d.battery * 100)}%` : d.name;
    }

    function setEnabled(on) { if (available) adapter.enabled = on; }
    function toggleDevice(d) { if (d.connected) d.disconnect(); else d.connect(); }
}
