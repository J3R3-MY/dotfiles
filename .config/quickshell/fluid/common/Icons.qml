pragma Singleton
import QtQuick
import Quickshell

// Nerd Font glyphs. Codepoints instead of literal characters so the files stay
// readable in any editor.
Singleton {
    function g(cp) { return String.fromCodePoint(cp); }

    // Workspace icons copied from the old waybar "format-icons"
    readonly property var workspaces: ({
        "1": g(0xf269), "2": g(0xf121), "3": g(0xf02d), "4": g(0xf07b),
        "5": g(0xf02bb), "6": g(0xf0e0), "7": g(0xf120), "8": g(0xf120),
        "9": g(0xf120)
    })

    readonly property string clock: g(0xf017)
    readonly property string calendar: g(0xf073)
    readonly property string cpu: g(0xf4bc)
    readonly property string memory: g(0xefc5)
    readonly property string wifi: g(0xf1eb)
    readonly property string wifiOff: g(0xf092e)
    readonly property string ethernet: g(0xf0200)
    readonly property string btOn: g(0xf00af)
    readonly property string btConnected: g(0xf00b1)
    readonly property string btOff: g(0xf00b2)
    readonly property string volHigh: g(0xf028)
    readonly property string volLow: g(0xf027)
    readonly property string volOff: g(0xf026)
    readonly property string volMute: g(0xf075f)
    readonly property string mic: g(0xf130)
    readonly property string micOff: g(0xf131)
    readonly property string sun: g(0xf185)
    readonly property string moon: g(0xf186)
    readonly property string bolt: g(0xf0e7)
    readonly property string play: g(0xf04b)
    readonly property string pause: g(0xf04c)
    readonly property string next: g(0xf051)
    readonly property string prev: g(0xf048)
    readonly property string music: g(0xf001)
    readonly property string search: g(0xf002)
    readonly property string clipboard: g(0xf0ea)
    readonly property string palette: g(0xf03d8)
    readonly property string bell: g(0xf0f3)
    readonly property string bellOff: g(0xf1f6)
    readonly property string close: g(0xf00d)
    readonly property string power: g(0xf011)
    readonly property string lock: g(0xf023)
    readonly property string sliders: g(0xf1de)

    function battery(pct, charging) {
        if (charging) return g(0xf0084);
        const steps = [0xf244, 0xf243, 0xf242, 0xf241, 0xf240];
        return g(steps[Math.min(4, Math.floor(pct / 20.01))]);
    }

    function volume(pct, muted) {
        if (muted || pct <= 0) return volMute;
        return pct < 34 ? volOff : pct < 67 ? volLow : volHigh;
    }
}
