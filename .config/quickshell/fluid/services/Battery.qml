pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool available: !!device && device.isLaptopBattery
    readonly property int percent: available ? Math.round(device.percentage * 100) : 0
    readonly property bool charging: available && (device.state === UPowerDeviceState.Charging
                                                   || device.state === UPowerDeviceState.FullyCharged
                                                   || device.state === UPowerDeviceState.PendingCharge)
    // waybar states: warning 30, critical 15
    readonly property bool warning: available && !charging && percent <= 30
    readonly property bool critical: available && !charging && percent <= 15

    readonly property string timeLeft: {
        if (!available) return "";
        const secs = charging ? device.timeToFull : device.timeToEmpty;
        if (!secs || secs <= 0) return "";
        const h = Math.floor(secs / 3600);
        const m = Math.round((secs % 3600) / 60);
        return (h > 0 ? h + "h " : "") + m + "m";
    }
}
