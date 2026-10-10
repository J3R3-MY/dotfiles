pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Weather from Open-Meteo (free, no API key).
// Location: ~/.local/state/fluid/location ("lat,lon,City"), set once by
// typing your city in the dashboard (looked up with Open-Meteo's geocoder).
// Nothing else about you is sent anywhere.
Singleton {
    id: root

    readonly property string locFile: Quickshell.env("HOME") + "/.local/state/fluid/location"

    property real lat: NaN
    property real lon: NaN
    property string city: ""
    property bool ready: false

    // Current conditions
    property real temp: 0
    property real feels: 0
    property int humidity: 0
    property real wind: 0          // km/h
    property int rainChance: 0     // % for the current hour
    property int code: 0
    property bool isDay: true
    // Next 24 hours: [{ time: Date, temp, code, rain }]
    property var hourly: []
    // Next 7 days: [{ date: Date, min, max, code }]
    property var daily: []

    readonly property string icon: iconFor(code, isDay)
    readonly property string summary: textFor(code)

    function iconFor(c, day) {
        const g = cp => String.fromCodePoint(cp);
        if (c === 0) return day ? g(0xf185) : g(0xf186);              // clear
        if (c <= 2) return day ? g(0xf0595) : g(0xf0f31);             // partly cloudy
        if (c === 3) return g(0xf0590);                               // overcast
        if (c === 45 || c === 48) return g(0xf0591);                  // fog
        if (c >= 51 && c <= 67) return g(0xf0597);                    // drizzle / rain
        if (c >= 71 && c <= 77) return g(0xf0598);                    // snow
        if (c >= 80 && c <= 82) return g(0xf0596);                    // showers
        if (c >= 85 && c <= 86) return g(0xf0f36);                    // snow showers
        if (c >= 95) return g(0xf0593);                               // thunder
        return g(0xf0590);
    }

    function textFor(c) {
        const t = { 0: "Clear", 1: "Mostly clear", 2: "Partly cloudy", 3: "Overcast", 45: "Fog", 48: "Rime fog",
            51: "Light drizzle", 53: "Drizzle", 55: "Heavy drizzle", 56: "Freezing drizzle", 57: "Freezing drizzle",
            61: "Light rain", 63: "Rain", 65: "Heavy rain", 66: "Freezing rain", 67: "Freezing rain",
            71: "Light snow", 73: "Snow", 75: "Heavy snow", 77: "Snow grains",
            80: "Light showers", 81: "Showers", 82: "Heavy showers", 85: "Snow showers", 86: "Snow showers",
            95: "Thunderstorm", 96: "Thunderstorm, hail", 99: "Thunderstorm, hail" };
        return t[c] || "—";
    }

    readonly property bool located: !isNaN(lat)

    function setCity(name) {
        if (!name.trim()) return;
        locate.command = ["curl", "-fsS", "--max-time", "10", "-G", "https://geocoding-api.open-meteo.com/v1/search",
                          "--data-urlencode", "name=" + name.trim(), "-d", "count=1"];
        locate.running = true;
    }

    function refresh() {
        if (!located) return;
        fetcher.command = ["curl", "-fsS", "--max-time", "15",
            "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon +
            "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day" +
            "&hourly=temperature_2m,weather_code,precipitation_probability" +
            "&daily=temperature_2m_max,temperature_2m_min,weather_code" +
            "&timezone=auto&forecast_days=7"];
        fetcher.running = true;
    }

    FileView {
        path: root.locFile
        printErrors: false
        onLoaded: {
            const p = text().trim().split(",");
            if (p.length >= 2 && !isNaN(parseFloat(p[0]))) {
                root.lat = parseFloat(p[0]);
                root.lon = parseFloat(p[1]);
                root.city = p.slice(2).join(",").trim();
            }
            root.refresh();
        }
    }

    // City -> coordinates, written to the location file
    Process {
        id: locate
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text).results[0];
                    root.lat = r.latitude;
                    root.lon = r.longitude;
                    root.city = r.name;
                    Quickshell.execDetached(["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' \"$2\" > \"$1\"",
                        "sh", root.locFile, root.lat + "," + root.lon + "," + root.city]);
                    root.refresh();
                } catch (e) { root.city = ""; }
            }
        }
    }

    Process {
        id: fetcher
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    const c = j.current;
                    root.temp = c.temperature_2m;
                    root.feels = c.apparent_temperature;
                    root.humidity = c.relative_humidity_2m;
                    root.wind = c.wind_speed_10m;
                    root.code = c.weather_code;
                    root.isDay = c.is_day === 1;

                    const now = Date.now();
                    const hrs = [];
                    for (let i = 0; i < j.hourly.time.length && hrs.length < 24; i++) {
                        const t = new Date(j.hourly.time[i]);
                        if (t.getTime() < now - 3600000) continue;
                        hrs.push({ time: t, temp: j.hourly.temperature_2m[i], code: j.hourly.weather_code[i],
                                   rain: j.hourly.precipitation_probability[i] || 0 });
                    }
                    root.hourly = hrs;
                    root.rainChance = hrs.length ? hrs[0].rain : 0;

                    const days = [];
                    for (let i = 0; i < j.daily.time.length; i++)
                        days.push({ date: new Date(j.daily.time[i]), min: j.daily.temperature_2m_min[i],
                                    max: j.daily.temperature_2m_max[i], code: j.daily.weather_code[i] });
                    root.daily = days;
                    root.ready = true;
                } catch (e) {
                    console.warn("fluid: weather parse failed", e);
                }
            }
        }
    }

    Timer { interval: 30 * 60 * 1000; running: true; repeat: true; onTriggered: root.refresh() }
}
