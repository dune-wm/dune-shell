pragma Singleton

import QtQuick
import Quickshell

// The colors and sizes of the corners, taken from the waybar style they replace.
Singleton {
    readonly property color background: "#1E293B"
    readonly property color surface: "#334155"
    readonly property color text: "#E2E8F0"
    readonly property color muted: "#64748B"
    readonly property color accent: "#38BDF8"
    readonly property color alert: "#EF4444"
    readonly property color warn: "#FBBF24"
    // Text on an accent or alert background.
    readonly property color inverse: "#0F172A"

    readonly property string font: "RobotoMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int radius: 8
    readonly property int padding: 10
    readonly property int margin: 6
    // Every pill is this tall, whatever it holds, so both corners match.
    readonly property int pillHeight: 40
    // Room above the right pill for the tooltip of the widget under the cursor.
    readonly property int hintSpace: 200

    // The strip on the bottom edge that wakes a corner up.
    readonly property int triggerWidth: 200
    readonly property int triggerHeight: 2
    // How long the cursor rests on the strip before the corner shows, and how long the
    // corner stays after the cursor leaves it.
    readonly property int showDelay: 120
    readonly property int hideDelay: 300
}
