pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The colors, sizes and delays of the corners. Each one can be set in the settings file,
// `$XDG_CONFIG_HOME/dune/shell.json` (`~/.config/dune/shell.json`), by its name here; a
// value left out (or the whole file, or one that does not parse) keeps the default
// written below. The file is read again when it changes. See shell.example.json.
Singleton {
    id: theme

    // What the file says, {} until it is read.
    property var settings: ({})
    readonly property string settingsPath: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/dune/shell.json"

    // The file's value for `name`, else `fallback`.
    function pick(name, fallback) {
        const value = settings[name];
        return value === undefined || value === null ? fallback : value;
    }

    FileView {
        id: file
        path: theme.settingsPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                theme.settings = parsed !== null && typeof parsed === "object" ? parsed : {};
            } catch (e) {
                console.warn(`${theme.settingsPath}: ${e.message}; the defaults stay`);
                theme.settings = {};
            }
        }
        onLoadFailed: theme.settings = {}
    }

    readonly property color background: pick("background", "#1E293B")
    readonly property color surface: pick("surface", "#334155")
    readonly property color text: pick("text", "#E2E8F0")
    readonly property color muted: pick("muted", "#64748B")
    readonly property color accent: pick("accent", "#38BDF8")
    readonly property color alert: pick("alert", "#EF4444")
    readonly property color warn: pick("warn", "#FBBF24")
    // Text on an accent or alert background.
    readonly property color inverse: pick("inverse", "#0F172A")

    readonly property string font: pick("font", "RobotoMono Nerd Font")
    readonly property int fontSize: pick("fontSize", 13)
    readonly property int radius: pick("radius", 8)
    readonly property int padding: pick("padding", 10)
    readonly property int margin: pick("margin", 6)
    // Between the widgets of a pill (and around the separators of its groups).
    readonly property int itemSpacing: pick("itemSpacing", 14)
    // Every pill is this tall, whatever it holds, so both corners match.
    readonly property int pillHeight: pick("pillHeight", 48)
    // Room above the right pill for the tooltip of the widget under the cursor.
    readonly property int hintSpace: pick("hintSpace", 200)
    // How wide that tooltip can be, even past the pill's width.
    readonly property int hintWidth: pick("hintWidth", 640)
    // The monitor whose right widgets are split between its top and bottom corners;
    // the others keep them all at the bottom.
    readonly property string mainOutput: pick("mainOutput", "HDMI-A-1")
    // The minimap of the strip, opened from the middle of the top edge.
    // Its height is fixed; its width follows the strip at that scale, from the narrowest
    // to the monitor's width.
    readonly property int minimapMinWidth: pick("minimapMinWidth", 240)
    readonly property int minimapHeight: pick("minimapHeight", 180)
    // How long the minimap stays after the cursor leaves it (longer than the corners:
    // it is crossed on the way to a tile).
    readonly property int minimapHideDelay: pick("minimapHideDelay", 900)
    // The strip in the middle of the edge that opens it: wider than the corners' so it
    // is easy to hit.
    readonly property int minimapTriggerWidth: pick("minimapTriggerWidth", 400)
    // How often the thumbnails of its tiles are read again while it is open.
    readonly property int thumbnailRefresh: pick("thumbnailRefresh", 1000)
    // The edge whose middle opens the minimap, per monitor; others use the top.
    readonly property var minimapEdges: pick("minimapEdges", {
        "HDMI-A-2": "bottom" // the Asus MB16AMT
    })

    // Taskwarrior's data dir per mode, in the order the task widget switches them.
    readonly property var taskModes: pick("taskModes", {
        "personal": "~/.task",
        "work": "~/.task-work"
    })
    // Where the daily log goes, a file per day.
    readonly property string logDir: pick("logDir", "~/.local/share/dune/log")

    // The strip on the bottom edge that wakes a corner up.
    readonly property int triggerWidth: pick("triggerWidth", 200)
    readonly property int triggerHeight: pick("triggerHeight", 2)
    // How long the cursor rests on the strip before the corner shows, and how long the
    // corner stays after the cursor leaves it.
    readonly property int showDelay: pick("showDelay", 120)
    readonly property int hideDelay: pick("hideDelay", 300)
    // How long a corner takes to come in and to go back into the edge.
    readonly property int openDuration: pick("openDuration", 160)
    readonly property int closeDuration: pick("closeDuration", 180)
}
