pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// AirPods battery / noise control through scripts/fluid-pods.py, which talks
// to the pods directly over Bluetooth. Shown in the Bluetooth pill and on the
// Bluetooth page of the control center while AirPods are connected.
Singleton {
    id: root

    property var st: ({})
    readonly property bool connected: !!st.connected
    readonly property string name: st.name || "AirPods"
    readonly property var battery: st.battery || ({})
    readonly property string anc: st.anc || ""
    readonly property bool ca: !!st.ca
    readonly property bool isMax: !!battery.headset

    function level(part) { return battery[part] ? battery[part].level : -1; }
    function charging(part) { return battery[part] ? battery[part].charging : false; }
    // Lowest pod, what the bar shows
    readonly property int minPod: {
        const v = ["left", "right", "headset"].map(p => level(p)).filter(x => x >= 0);
        return v.length ? Math.min(...v) : -1;
    }

    function setAnc(mode) { send("anc " + mode); st = Object.assign({}, st, { anc: mode }); }
    function setCa(on) { send("ca " + (on ? "on" : "off")); st = Object.assign({}, st, { ca: on }); }
    function send(line) { if (bridge.running) bridge.write(line + "\n"); }

    Process {
        id: bridge
        running: true
        stdinEnabled: true
        command: ["python3", Quickshell.shellDir + "/scripts/fluid-pods.py"]
        stdout: SplitParser {
            onRead: line => { try { root.st = JSON.parse(line); } catch (e) {} }
        }
        onExited: restart.start()
    }
    // Keep it alive (e.g. after a Bluetooth stack restart)
    Timer { id: restart; interval: 10000; onTriggered: bridge.running = true }
}
