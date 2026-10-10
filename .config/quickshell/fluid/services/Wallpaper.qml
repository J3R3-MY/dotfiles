pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

// Wallpaper list, current wallpaper and the colour tweaks from the theme
// picker. Applying hands off to scripts/fluid-theme.sh, which runs matugen and
// pushes the colours to sway/wezterm; the shell picks them up by watching
// colors.json (see Theme.qml).
Singleton {
    id: root

    // Every place the wallpapers may live. .config/wallpapers is excluded by
    // .stow-global-ignore, so the repo checkout paths are searched as well.
    readonly property var dirs: {
        const h = Quickshell.env("HOME");
        return [h + "/.config/wallpapers", h + "/dotfiles/.config/wallpapers", h + "/Pictures/Wallpapers"];
    }
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/fluid"
    readonly property string script: Quickshell.shellDir + "/scripts/fluid-theme.sh"

    property var files: []
    // Average (saturation-boosted) colour per wallpaper, for the colour filter
    property var hues: ({})
    readonly property var colorFilters: [
        { id: "red", color: "#e5484d" }, { id: "orange", color: "#f76b15" }, { id: "yellow", color: "#ffc53d" },
        { id: "green", color: "#46a758" }, { id: "blue", color: "#3e63dd" }, { id: "purple", color: "#8e4ec6" },
        { id: "pink", color: "#d6409f" }, { id: "grey", color: "#8b8d98" }
    ]

    function bucket(path) {
        const hex = hues[path];
        if (!hex) return "";
        const c = Qt.lighter(hex, 1.0);
        if (c.hslSaturation < 0.18 || c.hslHue < 0) return "grey";
        const h = c.hslHue * 360;
        if (h < 15 || h >= 345) return "red";
        if (h < 45) return "orange";
        if (h < 70) return "yellow";
        if (h < 170) return "green";
        if (h < 255) return "blue";
        if (h < 290) return "purple";
        return "pink";
    }
    property string current: ""
    readonly property bool busy: applier.running

    // ---- Colour tweaks (persisted in tweaks.json) ---------------------------
    property string mode: "dark"          // "dark" | "light"
    property string scheme: "scheme-tonal-spot"
    property real contrast: 0             // -1 .. 1
    property real lightness: 0            // -0.3 .. 0.3, darker .. brighter
    property real hueShift: 0             // degrees, -180 .. 180
    property int sourceIndex: 0           // which wallpaper colour seeds the palette
    property var sourceColors: []         // candidates from matugen, "#rrggbb"

    // Palette styles offered in the picker, roughly calm -> loud
    readonly property var schemes: [
        { id: "scheme-monochrome", label: "Mono" },
        { id: "scheme-neutral", label: "Neutral" },
        { id: "scheme-tonal-spot", label: "Tonal" },
        { id: "scheme-content", label: "Content" },
        { id: "scheme-fidelity", label: "Fidelity" },
        { id: "scheme-vibrant", label: "Vibrant" },
        { id: "scheme-expressive", label: "Expressive" },
        { id: "scheme-rainbow", label: "Rainbow" },
        { id: "scheme-fruit-salad", label: "Fruit salad" }
    ]

    // The seed colour actually used: chosen wallpaper colour, hue-rotated
    // What the palette is built from, as passed to fluid-theme.sh. Without a
    // hue shift it's the wallpaper colour's index, so matugen always takes
    // the same route for the same settings (fresh pick or swatch click give
    // identical results); with a shift, the shifted colour as hex.
    readonly property string seed: {
        if (hueShift === 0) return String(Math.max(0, Math.min(3, sourceIndex)));
        const base = sourceColors[sourceIndex] || sourceColors[0] || "";
        return base ? rotateHue(base, hueShift) : String(sourceIndex);
    }

    function rotateHue(hex, deg) {
        const c = Qt.lighter(hex, 1.0);   // string -> color value
        if (deg === 0 || c.hslHue < 0) return hex;   // grey has no hue to rotate
        const h = ((c.hslHue + deg / 360) % 1 + 1) % 1;
        const out = Qt.hsla(h, c.hslSaturation, c.hslLightness, 1);
        const hx = v => Math.round(v * 255).toString(16).padStart(2, "0");
        return "#" + hx(out.r) + hx(out.g) + hx(out.b);
    }

    function rescan() { lister.running = true; }
    function probeSources() { if (root.current) sourceProbe.probe(root.current); }

    // Pick a new wallpaper: its own colours, keep style/contrast/brightness
    function apply(path) {
        root.current = path;
        root.sourceIndex = 0;
        root.hueShift = 0;
        root.sourceColors = [];
        sourceProbe.probe(path);
        run();
    }

    // Re-run matugen with the current tweaks (debounced, sliders call this a lot)
    function retheme() {
        saveTweaks();
        debounce.restart();
    }

    function setMode(m) { if (m !== mode) { mode = m; retheme(); } }

    function reset() {
        scheme = "scheme-tonal-spot";
        contrast = 0;
        lightness = 0;
        hueShift = 0;
        sourceIndex = 0;
        retheme();
    }

    function shuffle() {
        scheme = schemes[Math.floor(Math.random() * schemes.length)].id;
        hueShift = Math.round((Math.random() * 2 - 1) * 12) * 5;   // same 5° steps as the slider
        sourceIndex = sourceColors.length > 0 ? Math.floor(Math.random() * sourceColors.length) : 0;
        contrast = Math.round((Math.random() * 0.6 - 0.1) * 10) / 10;
        retheme();
    }

    function run() {
        if (!root.current) return;
        if (applier.running) { pending = true; return; }
        // fixed decimals: slider steps like 0.15000000000000002 must not
        // make the same setting produce a (slightly) different palette
        applier.command = [root.script, root.current, root.mode, root.scheme,
                           root.contrast.toFixed(2), root.lightness.toFixed(2), root.seed];
        applier.running = true;
    }
    property bool pending: false

    function saveTweaks() {
        tweaksFile.setText(JSON.stringify({
            mode: mode, scheme: scheme, contrast: contrast, lightness: lightness,
            hueShift: hueShift, sourceIndex: sourceIndex
        }));
    }

    Timer { id: debounce; interval: 220; onTriggered: root.run() }

    Process {
        id: lister
        running: true
        // Newest first, like the old `ls -t` picker; duplicates (same file
        // name in several dirs) are dropped
        command: ["sh", "-c", "for d; do [ -d \"$d\" ] && find -L \"$d\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) ! -name '._*' -printf '%T@\\t%f\\t%p\\n'; done | sort -rn | awk -F '\\t' '!seen[$2]++ { print $3 }'", "sh"].concat(root.dirs)
        stdout: StdioCollector {
            onStreamFinished: {
                root.files = text.split("\n").filter(l => l.length > 0);
                hueProbe.run();
            }
        }
    }

    // Fills `hues` for wallpapers not in the cache yet (ImageMagick, ~50 ms each)
    Process {
        id: hueProbe
        function run() {
            const missing = root.files.filter(f => !root.hues[f]);
            if (missing.length === 0 || running) return;
            command = ["sh", "-c", "for f; do printf '%s\\t%s\\n' \"$f\" \"$(magick \"$f\"[0] -resize 64x64 -modulate 100,180 -resize '1x1!' -format '%[hex:p{0,0}]' info: 2>/dev/null)\"; done", "sh"].concat(missing);
            running = true;
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const h = Object.assign({}, root.hues);
                for (const line of text.split("\n")) {
                    const [path, hex] = line.split("\t");
                    if (path && /^[0-9A-Fa-f]{6}/.test(hex || "")) h[path] = "#" + hex.slice(0, 6);
                }
                root.hues = h;
                huesFile.setText(JSON.stringify(h));
            }
        }
    }

    FileView {
        id: huesFile
        path: root.stateDir + "/wallhues.json"
        printErrors: false
        atomicWrites: true
        onLoaded: { try { root.hues = JSON.parse(text()); } catch (e) {} }
    }

    // Asks matugen which colours it would pick from the wallpaper
    Process {
        id: sourceProbe
        property string forPath: ""
        function probe(path) {
            forPath = path;
            running = false;
            command = ["matugen", "image", path, "--show-source-colors"];
            running = true;
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (sourceProbe.forPath !== root.current) return;
                const found = (text.match(/#[0-9a-fA-F]{6}\b/g) || []).slice(0, 4);
                root.sourceColors = found;
                if (root.sourceIndex >= found.length) root.sourceIndex = 0;
            }
        }
    }

    Process {
        id: applier
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) console.warn("fluid-theme:", text.trim())
        }
        onExited: if (root.pending) { root.pending = false; root.run(); }
    }

    Connections {
        target: Fluid
        function onThemeChanged() { stateView.reload(); }
    }

    FileView {
        id: stateView
        path: root.stateDir + "/wallpaper"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const p = text().trim();
            if (p.length > 0 && p !== root.current) {
                root.current = p;
                sourceProbe.probe(p);
            }
        }
    }

    FileView {
        id: tweaksFile
        path: root.stateDir + "/tweaks.json"
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                const t = JSON.parse(text());
                if (t.mode === "light" || t.mode === "dark") root.mode = t.mode;
                if (typeof t.scheme === "string") root.scheme = t.scheme;
                if (typeof t.contrast === "number") root.contrast = t.contrast;
                if (typeof t.lightness === "number") root.lightness = t.lightness;
                if (typeof t.hueShift === "number") root.hueShift = t.hueShift;
                if (typeof t.sourceIndex === "number") root.sourceIndex = t.sourceIndex;
            } catch (e) {}
        }
    }
}
