pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU and memory from /proc, same numbers waybar's cpu/memory modules show.
Singleton {
    id: root

    property int cpu: 0
    property int memory: 0
    property real memUsedGiB: 0
    property real memTotalGiB: 0

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
                if (dt > 0) root.cpu = Math.round(100 * (1 - di / dt));
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
        onTriggered: { stat.reload(); mem.reload(); }
    }
}
