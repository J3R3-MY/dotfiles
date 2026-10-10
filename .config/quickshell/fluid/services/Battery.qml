pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool available: !!device && device.isLaptopBattery
    readonly property int percent: available ? Math.round(device.percentage * 100) : 0
    readonly property bool charging: available && (device.state === UPowerDeviceState.Charging
                                                   || device.state === UPowerDeviceState.FullyCharged
                                                   || device.state === UPowerDeviceState.PendingCharge)
    // waybar's critical state (15 %)
    readonly property bool critical: available && !charging && percent <= 15

    readonly property string timeLeft: {
        if (!available) return "";
        const secs = charging ? device.timeToFull : device.timeToEmpty;
        if (!secs || secs <= 0) return "";
        const h = Math.floor(secs / 3600);
        const m = Math.round((secs % 3600) / 60);
        return (h > 0 ? h + "h " : "") + m + "m";
    }

    // ---- Power profiles (power-profiles-daemon) ----------------------------
    readonly property int profile: PowerProfiles.profile
    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile
    function setProfile(p) { PowerProfiles.profile = p; }

    // ---- Uptime -------------------------------------------------------------
    property real uptimeSecs: 0
    readonly property string uptime: {
        const s = Math.floor(uptimeSecs);
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
        return (d > 0 ? d + "d " : "") + h + "h " + String(m).padStart(2, "0") + "m";
    }
    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptimeSecs = parseFloat(text().split(" ")[0]) || 0
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: uptimeFile.reload() }
}
