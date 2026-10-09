import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

// Keybind cheat sheet, generated from the live sway config every time it opens,
// so new binds show up without touching this file.
//  - descriptions come from the comment line right above a bindsym
//  - sections come from header comments ("# Workspaces:", "### Key bindings",
//    "# VOLUME", ...) and mode blocks
//  - runs like $mod+1..0 collapse into one row
Item {
    id: root

    property var sections: []      // [{ title, rows: [{ keys: [..], desc }] }]

    Keys.onEscapePressed: Fluid.closeAll()
    Component.onCompleted: { reader.running = true; search.focusInput(); }

    // Main config plus every user include (system /etc includes are skipped)
    Process {
        id: reader
        command: ["sh", "-c",
            "cfg=\"$HOME/.config/sway/config\"; emit() { echo \"#@@FILE $1\"; cat \"$1\"; }; emit \"$cfg\"; " +
            "grep -E '^[[:space:]]*include[[:space:]]' \"$cfg\" | awk '{print $2}' | while read -r p; do " +
            "p=$(echo \"$p\" | sed \"s|^~|$HOME|\"); for f in $p; do [ -f \"$f\" ] && case \"$f\" in /etc/*) ;; *) emit \"$f\";; esac; done; done"]
        stdout: StdioCollector { onStreamFinished: root.sections = root.parse(text) }
    }

    // ---------------------------------------------------------------- parsing
    function parse(text) {
        const vars = { "$mod": "Super" };
        const out = [];
        let section = null;
        let lastComment = "";      // first line of the comment block right above
        let modeName = "";
        let beforeMode = null;

        function startSection(title) {
            title = title.replace(/[:#]+$/, "").trim();
            title = title.charAt(0).toUpperCase() + title.slice(1).toLowerCase();
            section = out.find(s => s.title === title);
            if (!section) { section = { title: title, rows: [] }; out.push(section); }
        }
        function subst(s) {
            return s.replace(/\$[A-Za-z_]\w*/g, v => vars[v] !== undefined ? vars[v] : v);
        }

        for (let raw of text.split("\n")) {
            const line = raw.trim();
            if (line.startsWith("#@@FILE")) { lastComment = ""; continue; }
            if (line === "") { lastComment = ""; continue; }

            if (line.startsWith("#")) {
                const c = line.replace(/^#+\s*/, "");
                if (/^bindsym\b/.test(c) || /^\w+\s*=/.test(c)) { lastComment = ""; continue; }  // commented-out code
                const isHeader = /^###/.test(line)
                    || (c.length < 40 && (/:$/.test(c) || (c.length > 2 && c === c.toUpperCase() && /[A-Z]/.test(c))));
                if (isHeader) { startSection(c.replace(/\(.*\)/, "")); lastComment = ""; }
                else if (!lastComment) lastComment = c;
                continue;
            }

            let m;
            if ((m = line.match(/^set\s+(\$\w+)\s+(.+)$/))) {
                vars[m[1]] = m[2].replace(/^Mod4$/, "Super").replace(/^Mod1$/, "Alt");
                continue;
            }
            if ((m = line.match(/^mode\s+"([^"]+)"\s*\{/))) { modeName = m[1]; beforeMode = section; startSection("Mode: " + modeName); continue; }
            if (line === "}" && modeName) { modeName = ""; section = beforeMode; continue; }

            if ((m = line.match(/^bindsym\s+((?:--[\w-]+\s+)*)(\S+)\s+(.+)$/))) {
                if (!section) startSection("General");
                const keys = subst(m[2]).replace(/Mod4/g, "Super").replace(/Mod1/g, "Alt").split("+");
                const cmd = subst(m[3]);
                const known = describe(cmd, keys);
                section.rows.push({ keys: keys, desc: known || lastComment || fallback(cmd), cmd: cmd });
                lastComment = "";
            } else {
                lastComment = "";
            }
        }

        for (const s of out) s.rows = collapse(s.rows);
        return out.filter(s => s.rows.length > 0);
    }

    // Friendly text for commands we recognise; "" means "use the comment"
    function describe(cmd, keys) {
        const key = keys[keys.length - 1];
        const media = {
            XF86AudioMute: "Mute", XF86AudioRaiseVolume: "Volume up", XF86AudioLowerVolume: "Volume down",
            XF86AudioMicMute: "Mute microphone", XF86MonBrightnessUp: "Brightness up",
            XF86MonBrightnessDown: "Brightness down", XF86AudioPlay: "Play / pause", XF86AudioPause: "Play / pause",
            XF86AudioNext: "Next track", XF86AudioPrev: "Previous track", Print: "Screenshot"
        };
        if (keys.length === 1 && media[key]) return media[key];

        const known = [
            [/fluid ipc call fluid toggle (\w+)/, (_, v) => ({ launcher: "App launcher", clipboard: "Clipboard history", media: "Media player",
                calendar: "Dashboard (calendar, weather, screen time)", theme: "Wallpaper & theme picker", keys: "This cheat sheet",
                spotify: "Spotify library", vault: "Bitwarden passwords", lockstyle: "Lock screen style" }[v] || v)],
            [/fluid ipc call fluid network/, () => "Network panel (traffic, health, VPN, ports)"],
            [/fluid ipc call fluid controlCenter/, () => "Control center"],
            [/fluid ipc call fluid power/, () => "Power panel"],
            [/fluid-lock\.sh/, () => "Lock screen"],
            [/fluid ipc call fluid close/, () => "Close panel"],
            [/fluid-launch\.sh classic/, () => "Switch to waybar"],
            [/fluid-launch\.sh fluid/, () => "Switch to fluid shell"],
            [/^move container to workspace number (\d+)/, (_, n) => "Move window to workspace " + n],
            [/^workspace number (\d+)/, (_, n) => "Workspace " + n],
            [/^workspace back_and_forth/, () => "Previous workspace"],
            [/^move workspace to output (\S+)/, (_, o) => "Move workspace to " + o.replace(/^\$mon_/, "") + (o.startsWith("$mon_") ? " monitor" : "")],
            [/^focus (left|right|up|down)$/, (_, d) => "Focus " + d],
            [/^focus parent/, () => "Focus parent container"],
            [/^focus mode_toggle/, () => "Toggle focus tiling / floating"],
            [/^move (left|right|up|down)$/, (_, d) => "Move window " + d],
            [/^move scratchpad/, () => "Send window to scratchpad"],
            [/^scratchpad show/, () => "Show / cycle scratchpad"],
            [/^resize (shrink|grow) (\w+)/, (_, a, b) => (a === "grow" ? "Grow " : "Shrink ") + b],
            [/^layout toggle split/, () => "Toggle split direction"],
            [/^layout (\w+)/, (_, l) => "Layout: " + l],
            [/^fullscreen/, () => "Fullscreen"],
            [/^floating toggle/, () => "Toggle floating"],
            [/^mode "?default"?/, () => "Leave mode"],
            [/^mode "?(\w+)"?/, (_, n) => "Enter " + n + " mode"],
            [/^kill$/, () => "Close window"],
            [/^reload$/, () => "Reload sway config"]
        ];
        for (const [re, f] of known) {
            const m = cmd.match(re);
            if (m) return f(...m);
        }
        return "";
    }

    function fallback(cmd) {
        // "exec grimshot --notify savecopy area" -> "Run grimshot savecopy area"
        let m = cmd.match(/^exec\s+(?:--no-startup-id\s+)?(?:\S*\/)?([\w.-]+)(.*)$/);
        if (m) {
            if (/^(bash|sh|zsh)$/.test(m[1])) return "Run shell command";
            const args = m[2].trim().split(/\s+/).filter(a => a && !a.startsWith("-") && !/[|&;'"$]/.test(a)).slice(0, 2);
            return ["Run", m[1]].concat(args).join(" ");
        }
        return cmd.charAt(0).toUpperCase() + cmd.slice(1);
    }

    // $mod+1 .. $mod+0 with matching commands -> one row "Super + 1…0"
    function collapse(rows) {
        const out = [];
        for (let i = 0; i < rows.length; i++) {
            const r = rows[i];
            const last = r.keys[r.keys.length - 1];
            if (/^\d$/.test(last)) {
                const prefix = r.keys.slice(0, -1).join("+");
                const shape = r.cmd.replace(/\d+/g, "N");
                let j = i;
                while (j + 1 < rows.length) {
                    const n = rows[j + 1];
                    const nl = n.keys[n.keys.length - 1];
                    if (/^\d$/.test(nl) && n.keys.slice(0, -1).join("+") === prefix && n.cmd.replace(/\d+/g, "N") === shape) j++;
                    else break;
                }
                if (j > i) {
                    const firstKey = last, lastKey = rows[j].keys[rows[j].keys.length - 1];
                    out.push({ keys: r.keys.slice(0, -1).concat([firstKey + "…" + lastKey]),
                               desc: r.desc.replace(/\d+$/, "N").replace(/\d+/, "N") });
                    i = j;
                    continue;
                }
            }
            out.push(r);
        }
        return out;
    }

    // ---------------------------------------------------------------- filtering
    readonly property var filtered: {
        const q = search.text.trim().toLowerCase();
        if (!q) return sections;
        return sections.map(s => ({
            title: s.title,
            rows: s.rows.filter(r => r.desc.toLowerCase().includes(q) || r.keys.join("+").toLowerCase().includes(q)
                                     || s.title.toLowerCase().includes(q))
        })).filter(s => s.rows.length > 0);
    }

    // Spread sections over 3 columns, always filling the shortest one
    readonly property var columns: {
        const cols = [[], [], []], h = [0, 0, 0];
        for (const s of filtered) {
            const i = h.indexOf(Math.min(...h));
            cols[i].push(s);
            h[i] += s.rows.length + 2;
        }
        return cols;
    }

    // ---------------------------------------------------------------- view
    Row {
        id: header
        width: parent.width
        spacing: 12
        Glyph { text: Icons.g(0xf11c); color: Theme.clock; size: 22; anchors.verticalCenter: parent.verticalCenter }
        SearchField {
            id: search
            width: parent.width - 34
            placeholder: "Search keybinds  (Super = Windows key)"
        }
    }

    Flickable {
        anchors.top: header.bottom
        anchors.topMargin: 14
        anchors.bottom: parent.bottom
        width: parent.width
        contentHeight: cols.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Row {
            id: cols
            width: parent.width
            spacing: 16

            Repeater {
                model: root.columns
                Column {
                    id: column
                    required property var modelData
                    width: (cols.width - 32) / 3
                    spacing: 16

                    Repeater {
                        model: column.modelData
                        Column {
                            id: sec
                            required property var modelData
                            width: column.width
                            spacing: 4

                            Text {
                                text: sec.modelData.title
                                color: Theme.clock
                                font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; font.weight: Font.DemiBold
                                bottomPadding: 2
                            }

                            Repeater {
                                model: sec.modelData.rows
                                Item {
                                    id: row
                                    required property var modelData
                                    width: sec.width
                                    height: 28

                                    Row {
                                        id: caps
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 3
                                        Repeater {
                                            model: row.modelData.keys
                                            Rectangle {
                                                required property string modelData
                                                height: 22; radius: 6
                                                width: Math.max(22, keyText.implicitWidth + 12)
                                                color: Theme.surfaceHi
                                                border.width: 1
                                                border.color: Theme.border
                                                Text {
                                                    id: keyText
                                                    anchors.centerIn: parent
                                                    text: parent.modelData.replace(/^XF86/, "")
                                                    color: Theme.fg
                                                    font.family: "JetBrains Mono"; font.pixelSize: Theme.fontSize - 5
                                                }
                                            }
                                        }
                                    }
                                    Text {
                                        anchors.left: caps.right
                                        anchors.leftMargin: 10
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        elide: Text.ElideRight
                                        text: row.modelData.desc
                                        color: Theme.fg
                                        font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: root.filtered.length === 0
            text: root.sections.length === 0 ? "Reading sway config…" : "No keybinds match"
            color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize
        }
    }
}
