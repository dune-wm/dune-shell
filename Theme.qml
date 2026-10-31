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

    readonly property string font: "RobotoMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int radius: 8
    readonly property int padding: 10
    readonly property int margin: 6

    // The strip on the bottom edge that wakes a corner up.
    readonly property int triggerWidth: 48
    readonly property int triggerHeight: 2
    // How long the cursor rests on the strip before the corner shows, and how long the
    // corner stays after the cursor leaves it.
    readonly property int showDelay: 120
    readonly property int hideDelay: 300
}
