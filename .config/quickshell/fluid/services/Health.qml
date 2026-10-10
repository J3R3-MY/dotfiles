pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Connection health, split in two legs like Nexthop: this machine -> router
// (the default gateway) and router -> internet (Quad9, 9.9.9.9). Pings both
// every 15 s, keeps 30 minutes of history, scores 0-100 and logs outages to
// ~/.local/state/fluid/outages.json. The speed test is on demand only
// (Cloudflare's speed endpoints via curl). No root, no extra packages.
Singleton {
    id: root

    readonly property string internetHost: "9.9.9.9"
    property string gateway: ""

    // per leg: { last (ms or -1), avg, jitter, loss (0..1), samples: [ms or -1] }
    property var lan: ({ last: -1, avg: 0, jitter: 0, loss: 0, samples: [] })
    property var wan: ({ last: -1, avg: 0, jitter: 0, loss: 0, samples: [] })

    readonly property int score: {
        if (wan.samples.length === 0) return 100;
        let s = 100;
        s -= Math.min(40, Math.max(0, wan.avg - 30) / 4);      // latency
        s -= Math.min(20, wan.jitter / 2);                      // jitter
        s -= Math.min(40, wan.loss * 200);                      // loss
        s -= Math.min(15, lan.loss * 100 + Math.max(0, lan.avg - 15) / 4);
        return Math.max(0, Math.round(s));
    }
    // Where the problem is, in plain words
    readonly property string verdict: {
        if (wan.samples.length < 3) return "Measuring…";
        if (lan.loss > 0.3) return "Wi-Fi / router link is dropping packets";
        if (wan.loss > 0.3 && lan.loss < 0.05) return "Router is fine, the internet side is failing";
        if (lan.avg > 40) return "Slow link to the router";
        if (wan.avg - lan.avg > 120) return "Router is fine, the ISP is slow";
        if (score >= 80) return "Connection looks good";
        return "Connection is a bit unstable";
    }

    property var outages: []                 // [{ start, end, leg }]
    property real outageStart: 0
    property string outageLeg: ""

    property real speedDown: -1              // Mbit/s, -1 = not measured
    property real speedUp: -1
    property bool testing: false

    function stats(samples) {
        const ok = samples.filter(v => v >= 0);
        const avg = ok.length ? ok.reduce((a, b) => a + b, 0) / ok.length : 0;
        let j = 0;
        for (let i = 1; i < ok.length; i++) j += Math.abs(ok[i] - ok[i - 1]);
        return { avg: avg, jitter: ok.length > 1 ? j / (ok.length - 1) : 0,
                 loss: samples.length ? (samples.length - ok.length) / samples.length : 0 };
    }

    function push(leg, ms) {
        const old = root[leg];
        const samples = old.samples.concat([ms]).slice(-120);
        root[leg] = Object.assign({ last: ms, samples: samples }, stats(samples));
    }

    function speedTest() {
        if (testing) return;
        testing = true;
        speedDown = -1; speedUp = -1;
        speedProc.running = true;
    }

    // One round: gateway lookup + both pings, printed as "lan <ms|-1>" / "wan <ms|-1>"
    Process {
        id: pinger
        command: ["sh", "-c",
            "gw=$(ip route show default | awk '{print $3; exit}'); echo \"gw $gw\"; " +
            "p() { ping -n -c1 -W1 \"$1\" 2>/dev/null | sed -n 's/.*time=\\([0-9.]*\\).*/\\1/p'; }; " +
            "l=$( [ -n \"$gw\" ] && p \"$gw\"); w=$(p " + root.internetHost + "); " +
            "echo \"lan ${l:--1}\"; echo \"wan ${w:--1}\""]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const l of text.split("\n")) {
                    const [k, v] = l.split(" ");
                    if (k === "gw") root.gateway = v || "";
                    else if (k === "lan" || k === "wan") root.push(k, parseFloat(v));
                }
                root.trackOutage();
            }
        }
    }
    Timer { interval: 15000; running: true; repeat: true; triggeredOnStart: true; onTriggered: pinger.running = true }

    // 3 failures in a row on a leg = outage; it ends with the first success
    function trackOutage() {
        const failing = leg => { const s = root[leg].samples; return s.length >= 3 && s.slice(-3).every(v => v < 0); };
        const leg = failing("lan") ? "lan" : failing("wan") ? "wan" : "";
        if (leg && !outageStart) { outageStart = Date.now() - 45000; outageLeg = leg; }
        if (!leg && outageStart && root.wan.last >= 0) {
            const o = outages.concat([{ start: outageStart, end: Date.now(), leg: outageLeg }]).slice(-50);
            outages = o;
            outageStart = 0;
            outageFile.setText(JSON.stringify(o));
        }
    }

    FileView {
        id: outageFile
        path: Quickshell.env("HOME") + "/.local/state/fluid/outages.json"
        printErrors: false
        atomicWrites: true
        onLoaded: { try { root.outages = JSON.parse(text()); } catch (e) {} }
    }

    // 25 MB down, 10 MB up against Cloudflare; prints bytes/s for each
    Process {
        id: speedProc
        command: ["sh", "-c",
            "curl -s -o /dev/null -w '%{speed_download}\\n' 'https://speed.cloudflare.com/__down?bytes=25000000'; " +
            "head -c 10000000 /dev/zero | curl -s -o /dev/null -w '%{speed_upload}\\n' -X POST --data-binary @- 'https://speed.cloudflare.com/__up'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim().split("\n").map(Number);
                root.speedDown = v[0] ? v[0] * 8 / 1e6 : 0;
                root.speedUp = v[1] ? v[1] * 8 / 1e6 : 0;
                root.testing = false;
            }
        }
        onExited: root.testing = false
    }
}
