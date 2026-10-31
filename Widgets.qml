import QtQuick
import Quickshell

// Everything waybar showed, in its order, with the tooltip of the widget under the
// cursor above it.
Column {
    id: widgets

    // A tray menu is open: the corner has to stay.
    readonly property bool menuOpen: tray.menuOpen
    readonly property string hint: {
        const items = pill.items;
        for (let i = 0; i < items.length; i++) {
            if (items[i] === tray)
                continue;
            if (items[i].hovered)
                return items[i].tooltip;
        }
        return tray.hint;
    }

    spacing: Theme.margin

    Rectangle {
        anchors.right: parent.right
        visible: widgets.hint !== ""
        implicitWidth: hintLabel.width + 2 * Theme.padding
        implicitHeight: hintLabel.height + Theme.padding
        radius: Theme.radius
        color: Theme.background
        border.color: Theme.surface
        border.width: 1

        Label {
            id: hintLabel
            anchors.centerIn: parent
            text: widgets.hint
            // No wider than the pill and no taller than the room kept for it, so the
            // corner does not change size (see Corner.reserve).
            width: Math.min(implicitWidth, pill.width - 2 * Theme.padding)
            color: Theme.muted
            elide: Text.ElideNone
            wrapMode: Text.Wrap
            maximumLineCount: 9
        }
    }

    Pill {
        id: pill
        anchors.right: parent.right

        ScriptWidget {
            exec: "dune recording watch"
            watch: true
            colors: ({ idle: Theme.alert, recording: Theme.alert })
            leftClick: "dune recording menu"
            middleClick: "dune recording tile"
            rightClick: "dune recording screen"
            scrollUp: "dune recording audio"
            scrollDown: "dune recording audio"
        }
        ScriptWidget {
            exec: "php ~/data-disk/my-projects/waytask/task"
            interval: 60000
            colors: ({ error: Theme.alert })
            leftClick: "foot --app-id=waybar-float -e php ~/data-disk/my-projects/waytask/task shell"
            middleClick: "foot --app-id=waybar-float -e php ~/data-disk/my-projects/waytask/task done"
            rightClick: "php ~/data-disk/my-projects/waytask/task toggle"
        }
        ScriptWidget {
            exec: "php ~/data-disk/my-projects/timer/timer time"
            colors: ({ working: Theme.warn })
            leftClick: "foot --app-id=waybar-float -e php ~/data-disk/my-projects/timer/timer log"
            rightClick: "php ~/data-disk/my-projects/timer/timer reset"
        }
        ScriptWidget {
            exec: "~/.config/waybar/plugins/docker/docker-status"
            interval: 10000
            colors: ({ running: Theme.accent, stopped: Theme.muted })
            leftClick: "foot --app-id=waybar-float sh -c '~/.config/waybar/plugins/docker/docker-list; read'"
            rightClick: "docker stop $(docker ps -q)"
        }
        ScriptWidget {
            exec: "~/.config/waybar/plugins/vagrant/vagrant-status"
            interval: 15000
            colors: ({ running: "#2ECC71", stopped: Theme.muted })
            leftClick: "foot --app-id=waybar-float sh -c 'vagrant global-status; read'"
            rightClick: "foot --app-id=waybar-float sh -c '~/.config/waybar/plugins/vagrant/vagrant-reload; read'"
        }
        ScriptWidget {
            exec: "~/commands/vpn-check"
        }

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

        NetworkWidget {}
        BluetoothWidget {}
        Audio {}

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
        ScriptWidget {
            exec: "pamac checkupdates -q 2>/dev/null | wc -l"
            check: "[ $(pamac checkupdates -q 2>/dev/null | wc -l) -gt 0 ]"
            interval: 3600000
            format: "󰏖 {}"
            leftClick: "pamac-manager --updates"
        }

        Tray {
            id: tray
        }

        Widget {
            text: Qt.formatDateTime(clock.date, "ddd d  HH:mm")
            tooltip: Qt.formatDateTime(clock.date, "dddd d MMMM yyyy")
            leftClick: "foot --app-id=waybar-float sh -c 'cal -3; read'"
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
