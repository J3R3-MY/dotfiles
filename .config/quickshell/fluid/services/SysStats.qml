pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU and memory from /proc, same numbers waybar's cpu/memory modules show.
// Plus CPU history, temperatures and fans from /sys/class/hwmon for the
// dashboard's System tab (the NVIDIA GPU isn't asked: that would wake it).
Singleton {
    id: root

    property int cpu: 0
    property int memory: 0
    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property real cpuTemp: NaN           // °C, coretemp package
    property real diskTemp: NaN          // °C, NVMe
    property var fans: []                // rpm

    // hwmon sensor files, found once by their driver name
    property var hw: ({})
    Process {
        running: true
        command: ["sh", "-c", "for d in /sys/class/hwmon/hwmon*; do printf '%s %s\\n' \"$(cat $d/name)\" \"$d\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {};
                for (const l of text.split("\n")) { const [n, d] = l.split(" "); if (n && !m[n]) m[n] = d; }
                root.hw = m;
            }
        }
    }
    FileView { id: coreT; path: root.hw.coretemp ? root.hw.coretemp + "/temp1_input" : ""; onLoaded: root.cpuTemp = parseInt(text()) / 1000 }
    FileView { id: nvmeT; path: root.hw.nvme ? root.hw.nvme + "/temp1_input" : ""; onLoaded: root.diskTemp = parseInt(text()) / 1000 }
    FileView { id: fan1; path: root.hw.dell_smm ? root.hw.dell_smm + "/fan1_input" : ""; onLoaded: root.fans = [parseInt(text()), root.fans[1] || 0] }
    FileView { id: fan2; path: root.hw.dell_smm ? root.hw.dell_smm + "/fan2_input" : ""; onLoaded: root.fans = [root.fans[0] || 0, parseInt(text())] }

    property var _prev: null

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + (f[4] || 0);
            const total = f.reduce((a, b) => a + b, 0);
            if (root._prev) {
                const dt = total - root._prev.total;
                const di = idle - root._prev.idle;
                if (dt > 0) {
                    root.cpu = Math.round(100 * (1 - di / dt));
                }
            }
            root._prev = { total: total, idle: idle };
        }
    }

    FileView {
        id: mem
        path: "/proc/meminfo"
        onLoaded: {
            const kv = {};
            for (const line of text().split("\n")) {
                const m = line.match(/^(\w+):\s+(\d+)/);
                if (m) kv[m[1]] = parseInt(m[2]);
            }
            if (kv.MemTotal) {
                const used = kv.MemTotal - (kv.MemAvailable || 0);
                root.memory = Math.round(100 * used / kv.MemTotal);
                root.memUsedGiB = used / 1048576;
                root.memTotalGiB = kv.MemTotal / 1048576;
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            stat.reload(); mem.reload();
            for (const f of [coreT, nvmeT, fan1, fan2]) if (f.path) f.reload();
        }
    }
}
