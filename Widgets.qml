import QtQuick
import Quickshell

// Everything waybar showed, in its order, with the tooltip of the widget under the
// cursor next to it. `part` picks what this corner holds: "status" (work and system:
// recording to updates), "controls" (network to the clock) or "all" of it. On a top
// corner the tooltip goes under the pill.
Column {
    id: widgets

    property string part: "all"
    property string edge: "bottom"

    // A tray menu, the calendar, the tasks or the log are open: the corner has to stay.
    readonly property bool menuOpen: tray.menuOpen || calendar.menuOpen || tasks.menuOpen || dailyLog.menuOpen
    readonly property string hint: {
        const items = [...status.children, ...controls.children];
        for (let i = 0; i < items.length; i++) {
            if (items[i] === tray)
                continue;
            if (items[i].hovered)
                return items[i].tooltip;
        }
        return widgets.part !== "status" ? tray.hint : "";
    }

    spacing: Theme.margin

    // Inline components do not see this file's ids: what it shows comes in.
    component Hint: Rectangle {
        property alias text: hintLabel.text
        property real maxWidth: 0

        anchors.right: parent.right
        implicitWidth: hintLabel.width + 2 * Theme.padding
        implicitHeight: hintLabel.height + Theme.padding
        radius: Theme.radius
        color: Theme.background
        border.color: Theme.surface
        border.width: 1

        Label {
            id: hintLabel
            anchors.centerIn: parent
            // No wider than the pill (or `hintWidth`, if that is wider) and no taller than
            // the room kept for it, so the corner does not change size (see Corner.reserve
            // and Corner.reserveWidth).
            width: Math.min(implicitWidth, parent.maxWidth - 2 * Theme.padding)
            color: Theme.text
            elide: Text.ElideNone
            wrapMode: Text.Wrap
            maximumLineCount: 9
        }
    }

    Hint {
        visible: widgets.edge !== "top" && widgets.hint !== ""
        text: widgets.hint
        maxWidth: Math.max(pill.width, Theme.hintWidth)
    }

    Pill {
        id: pill
        anchors.right: parent.right

        Row {
            id: status
            visible: widgets.part !== "controls"
            spacing: Theme.itemSpacing

            ScriptWidget {
                exec: "dune recording watch"
                watch: true
                colors: ({ idle: Theme.alert, recording: Theme.alert })
                // Only the camera (and the time while recording), without dune's dots.
                drop: / ?[⏺●]/g
                leftClick: "dune recording menu"
                middleClick: "dune recording tile"
                rightClick: "dune recording screen"
                scrollUp: "dune recording audio"
                scrollDown: "dune recording audio"
            }
            Tasks {
                id: tasks
                edge: widgets.edge
            }
            Log {
                id: dailyLog
                edge: widgets.edge
            }
            ScriptWidget {
                exec: "~/commands/vpn-check"
            }

            Separator {}
            Widget {
                text: "󰻠 " + Stats.cpu + "%"
                color: Stats.cpu >= 90 ? Theme.alert : Stats.cpu >= 70 ? Theme.warn : Theme.text
                tooltip: "CPU"
                leftClick: "foot --app-id=waybar-float -e btop"
            }
            Widget {
                text: "󰍛 " + Stats.memory + "%"
                color: Stats.memory >= 90 ? Theme.alert : Stats.memory >= 70 ? Theme.warn : Theme.text
                tooltip: "Memory"
                leftClick: "foot --app-id=waybar-float -e btop"
            }
            Widget {
                text: "󰔏 " + Stats.temperature + "°"
                color: Stats.temperature >= 90 ? Theme.alert : Theme.text
                tooltip: "CPU temperature"
                leftClick: "foot --app-id=waybar-float -e watch sensors"
            }

            ScriptWidget {
                exec: "pamac checkupdates -q 2>/dev/null | wc -l"
                check: "[ $(pamac checkupdates -q 2>/dev/null | wc -l) -gt 0 ]"
                interval: 3600000
                format: "󰏖 {}"
                leftClick: "pamac-manager --updates"
                // Only in the main monitor's top corner, not with everything on the others.
                visible: text !== "" && widgets.part === "status"
            }
        }

        Separator {
            visible: widgets.part === "all"
        }

        Row {
            id: controls
            visible: widgets.part !== "status"
            spacing: Theme.itemSpacing

            NetworkWidget {}
            BluetoothWidget {}
            Audio {}

            Separator {}

            ScriptWidget {
                exec: "~/.config/waybar/plugins/nightlight/nightlight"
                check: "~/.config/waybar/plugins/nightlight/nightlight check"
                format: "{icon}"
                icons: ({ on: "", off: "" })
                colors: ({ on: "#FB923C", off: Theme.muted })
                leftClick: "~/.config/waybar/plugins/nightlight/nightlight toggle"
                scrollUp: "~/.config/waybar/plugins/nightlight/nightlight cooler"
                scrollDown: "~/.config/waybar/plugins/nightlight/nightlight warmer"
            }
            ScriptWidget {
                exec: "playerctl metadata --format '{\"alt\": \"{{status}}\", \"tooltip\": \"{{playerName}}:  {{markup_escape(title)}} - {{markup_escape(artist)}}\" }'"
                format: "{icon}"
                icons: ({ Playing: "󰐊", Paused: "󰏤" })
                leftClick: "playerctl play-pause"
                rightClick: "playerctl next"
                scrollUp: "playerctl position 10+"
                scrollDown: "playerctl position 10-"
            }
            ScriptWidget {
                exec: "~/.config/waybar/plugins/notifications/notifications"
                check: "~/.config/waybar/plugins/notifications/notifications check"
                colors: ({ filled: Theme.accent, empty: Theme.muted, dnd: "#F87171" })
                leftClick: "~/.config/waybar/plugins/notifications/notifications list"
                rightClick: "~/.config/waybar/plugins/notifications/notifications dnd"
                middleClick: "~/.config/waybar/plugins/notifications/notifications clear"
                scrollUp: "~/.config/waybar/plugins/notifications/notifications restore"
            }
            ScriptWidget {
                exec: "~/.config/waybar/plugins/clipboard/clipboard"
                check: "~/.config/waybar/plugins/clipboard/clipboard check"
                colors: ({ filled: "#A78BFA", empty: Theme.muted })
                leftClick: "~/.config/waybar/plugins/clipboard/clipboard list"
                rightClick: "~/.config/waybar/plugins/clipboard/clipboard clear"
                middleClick: "~/.config/waybar/plugins/clipboard/clipboard delete"
            }
            ScriptWidget {
                exec: "/usr/share/sway/scripts/wluma.sh"
                check: "/usr/share/sway/scripts/wluma.sh check"
                interval: 30000
                format: "{icon}"
                icons: ({ on: "󰃠", off: "󰃞" })
                leftClick: "/usr/share/sway/scripts/wluma.sh toggle"
            }

            Tray {
                id: tray
            }

            Separator {}
            Calendar {
                id: calendar
            }
        }
    }

    Hint {
        visible: widgets.edge === "top" && widgets.hint !== ""
        text: widgets.hint
        maxWidth: Math.max(pill.width, Theme.hintWidth)
    }
}
