import QtQuick
import Quickshell
import Quickshell.Io

// A window (dune tiles it like any other) to set the look of dune's tiles by hand: the
// colors of the borders and the background, how thick the borders are, the gap and the
// rounding of the corners. dune keeps them in its dune.toml; every change goes there
// at once through `dune config set`, which also has dune apply it, so it shows on the
// tiles while it is being chosen. Opened and closed with `qs -c dune ipc call settings toggle`.
FloatingWindow {
    id: settings

    // What `dune config get` said, changed here as they are set.
    property var values: ({})
    // Set but not written yet: the key -> value to write, in the order they came.
    property var pending: ({})
    // The color whose picker is open, "" when none.
    property string picking: ""
    property string error: ""

    function toggle() {
        visible = !visible;
    }

    onVisibleChanged: {
        if (visible) {
            error = "";
            reader.running = true;
        } else {
            picking = "";
        }
    }

    function put(key, value) {
        const next = Object.assign({}, values);
        next[key] = value;
        values = next;
        pending[key] = String(value);
        flush();
    }

    // One `dune config set` at a time (each rewrites the file): the next one waits for it,
    // and only the last value of a key that moved meanwhile is written.
    function flush() {
        if (writer.running)
            return;
        const keys = Object.keys(pending);
        if (keys.length === 0)
            return;
        const key = keys[0];
        const value = pending[key];
        delete pending[key];
        writer.command = ["dune", "config", "set", key, value];
        writer.running = true;
    }

    visible: false
    title: "dune settings"
    color: Theme.background
    implicitWidth: 360
    implicitHeight: content.implicitHeight + 2 * Theme.padding

    Process {
        id: reader
        command: ["dune", "config", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    settings.values = JSON.parse(text);
                } catch (e) {
                    settings.error = "dune config get: " + e.message;
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") settings.error = text.trim()
        }
    }

    Process {
        id: writer
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") settings.error = text.trim()
        }
        onExited: settings.flush()
    }

    // A few colors to pick in one click.
    readonly property var swatches: ["#ffffff", "#94a3b8", "#334155", "#14141a", "#000000", "#5c9ef2", "#38bdf8", "#22c55e", "#fbbf24", "#f97316", "#ef4444", "#a855f7"]

    component Heading: Label {
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 1
        topPadding: Theme.margin
    }

    component ColorRow: Column {
        id: row
        required property string key
        required property string name
        // Whether `none` (no border) is one of its values.
        property bool canBeNone: false
        readonly property string value: settings.values[key] ?? ""
        readonly property bool none: value === "none"
        readonly property bool open: settings.picking === key

        width: parent.width
        spacing: Theme.margin

        Row {
            width: parent.width
            spacing: Theme.margin

            Label {
                width: 130
                anchors.verticalCenter: parent.verticalCenter
                text: row.name
            }
            // The color, or a crossed box for none; a click opens the picker.
            Rectangle {
                width: 28
                height: 22
                radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: row.none || row.value === "" ? "transparent" : row.value
                border.color: row.open ? Theme.accent : Theme.surface
                border.width: row.open ? 2 : 1
                Label {
                    anchors.centerIn: parent
                    visible: row.none
                    text: "∅"
                    color: Theme.muted
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: settings.picking = row.open ? "" : row.key
                }
            }
            Rectangle {
                width: 96
                height: 22
                radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.surface
                border.color: hex.activeFocus ? Theme.accent : Theme.surface
                TextInput {
                    id: hex
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    selectByMouse: true
                    // What it says follows the value, except while it is being typed into.
                    Binding on text {
                        when: !hex.activeFocus
                        value: row.value
                    }
                    // A whole color typed is set at once, the rest waits.
                    onTextEdited: {
                        const t = text.trim();
                        if (/^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(t) || (row.canBeNone && t.toLowerCase() === "none"))
                            settings.put(row.key, t.toLowerCase() === "none" ? "none" : (t.startsWith("#") ? t : "#" + t).toLowerCase());
                    }
                    onAccepted: focus = false
                }
            }
            Label {
                visible: row.canBeNone
                anchors.verticalCenter: parent.verticalCenter
                text: row.none ? "off" : "on"
                color: row.none ? Theme.muted : Theme.accent
                MouseArea {
                    anchors.fill: parent
                    // Turned back on, it gets the default color.
                    onClicked: settings.put(row.key, row.none ? (row.key === "focus_color" ? "#5c9ef2" : "#ffffff") : "none")
                }
            }
        }

        Column {
            visible: row.open
            spacing: Theme.margin
            leftPadding: 130 + Theme.margin

            ColorPicker {
                color: row.none || row.value === "" ? "white" : row.value
                onPicked: value => settings.put(row.key, value.toString().slice(0, 7))
            }
            Flow {
                width: 260
                spacing: 4
                Repeater {
                    model: settings.swatches
                    Rectangle {
                        required property string modelData
                        width: 18
                        height: 18
                        radius: 3
                        color: modelData
                        border.color: row.value === modelData ? Theme.accent : Theme.surface
                        border.width: row.value === modelData ? 2 : 1
                        MouseArea {
                            anchors.fill: parent
                            onClicked: settings.put(row.key, parent.modelData)
                        }
                    }
                }
            }
        }
    }

    component NumberRow: Row {
        id: nrow
        required property string key
        required property string name
        required property int from
        required property int to
        property string unit: "px"
        // The slider moves in steps of 1/scale of the value (100: hundredths).
        property real scale: 1

        width: parent.width
        spacing: Theme.margin

        Label {
            width: 130
            anchors.verticalCenter: parent.verticalCenter
            text: nrow.name
        }
        NumberSlider {
            width: parent.width - 130 - 64 - 2 * Theme.margin
            anchors.verticalCenter: parent.verticalCenter
            from: nrow.from
            to: nrow.to
            value: Math.round((settings.values[nrow.key] ?? 0) * nrow.scale)
            onMoved: v => settings.put(nrow.key, v / nrow.scale)
        }
        Label {
            width: 64
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: (settings.values[nrow.key] ?? "") + (nrow.unit ? " " + nrow.unit : "")
            color: Theme.muted
        }
    }

    // On or off, clicked.
    component ToggleRow: Row {
        id: trow
        required property string key
        required property string name
        readonly property bool on: settings.values[key] ?? true

        width: parent.width
        spacing: Theme.margin

        Label {
            width: 130
            anchors.verticalCenter: parent.verticalCenter
            text: trow.name
        }
        Rectangle {
            width: 36
            height: 20
            radius: 10
            anchors.verticalCenter: parent.verticalCenter
            color: trow.on ? Theme.accent : Theme.surface
            Rectangle {
                width: 14
                height: 14
                radius: 7
                anchors.verticalCenter: parent.verticalCenter
                x: trow.on ? parent.width - width - 3 : 3
                color: Theme.text
                Behavior on x {
                    NumberAnimation { duration: 120 }
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: settings.put(trow.key, !trow.on)
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: content.implicitHeight + 2 * Theme.padding
        clip: true

        Column {
            id: content
            x: Theme.padding
            y: Theme.padding
            // Not wider than this however wide the tile is: the sliders stay a hand's length.
            width: Math.min(parent.width - 2 * Theme.padding, 520)
            spacing: Theme.margin

            Label {
                text: "Tiles"
                font.pixelSize: Theme.fontSize + 3
                font.bold: true
            }

            Heading { text: "Colors" }
            ColorRow { key: "focus_color"; name: "Focus border"; canBeNone: true }
            ColorRow { key: "border_color"; name: "Border"; canBeNone: true }
            ColorRow { key: "background_color"; name: "Background" }

            Heading { text: "Sizes" }
            NumberRow { key: "border_width"; name: "Border width"; from: 0; to: 16 }
            NumberRow { key: "gap"; name: "Gap"; from: 0; to: 64 }
            NumberRow { key: "corner_radius"; name: "Corner radius"; from: 0; to: 64 }

            Heading { text: "Tabs" }
            ColorRow { key: "tabs.background"; name: "Bar" }
            ColorRow { key: "tabs.active"; name: "Shown tab" }
            ColorRow { key: "tabs.text"; name: "Shown title" }
            ColorRow { key: "tabs.inactive_text"; name: "Other titles" }
            NumberRow { key: "tabs.height"; name: "Bar height"; from: 16; to: 64 }
            NumberRow { key: "tabs.font_size"; name: "Title size"; from: 8; to: 32 }

            Heading { text: "Animations" }
            ToggleRow { id: animated; key: "animations.enabled"; name: "Animate" }
            Column {
                width: parent.width
                spacing: Theme.margin
                // Off, the durations stay as they were but do nothing.
                opacity: animated.on ? 1 : 0.4
                enabled: animated.on

                NumberRow { key: "animations.resize_ms"; name: "Resize"; from: 0; to: 1000; unit: "ms" }
                NumberRow { key: "animations.close_ms"; name: "Close"; from: 0; to: 1000; unit: "ms" }
                NumberRow { key: "animations.close_scale"; name: "Close shrinks to"; from: 50; to: 100; scale: 100; unit: "" }
            }

            Label {
                width: parent.width
                visible: settings.error !== ""
                text: settings.error
                color: Theme.alert
                wrapMode: Text.Wrap
                elide: Text.ElideNone
            }
            Label {
                width: parent.width
                topPadding: Theme.margin
                text: "Saved in ~/.config/dune/dune.toml as it changes."
                color: Theme.muted
                font.pixelSize: Theme.fontSize - 2
                wrapMode: Text.Wrap
                elide: Text.ElideNone
            }
        }
    }
}
