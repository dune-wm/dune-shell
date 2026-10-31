import QtQuick
import Quickshell.Io

// A waybar custom module, so the scripts written for waybar keep working: `exec` runs
// every `interval` ms (or once and keeps writing lines, with `watch`), and each line
// is waybar's JSON ({text, alt, tooltip, class}) or plain text. `format` puts the text
// at {} and the icon of `alt` at {icon}. With `check` (waybar's exec-if) the widget only
// shows while that command succeeds.
Widget {
    id: widget

    property string exec
    property string check: ""
    property int interval: 5000
    property bool watch: false
    property string format: "{}"
    property var icons: ({})
    // Text color per class.
    property var colors: ({})

    property string output: ""
    property string alt: ""
    property string kind: ""

    text: format.replace("{}", output).replace("{icon}", icons[alt] ?? "").trim()
    color: colors[kind] ?? Theme.text
    visible: text !== ""

    function show(line) {
        line = line.trim();
        try {
            const out = JSON.parse(line);
            output = String(out.text ?? "");
            alt = String(out.alt ?? "");
            kind = String(out.class ?? "");
            tooltip = String(out.tooltip ?? "");
        } catch (e) {
            output = line.split("\n")[0];
            alt = "";
            kind = "";
            tooltip = "";
        }
    }

    function clear() {
        output = "";
        alt = "";
        kind = "";
        tooltip = "";
    }

    // A click may change what the module says: ask again a moment later.
    onRan: if (!watch) refresh.restart()

    Process {
        id: process
        // 99: `check` failed, the module has nothing to show.
        command: ["sh", "-c", widget.check === "" ? widget.exec
            : `if ${widget.check} >/dev/null 2>&1; then ${widget.exec}; else exit 99; fi`]
        running: true

        stdout: widget.watch ? lines : collector

        onExited: code => {
            if (code === 99)
                widget.clear();
            if (widget.watch)
                restart.start();
        }
    }

    SplitParser {
        id: lines
        onRead: line => widget.show(line)
    }

    StdioCollector {
        id: collector
        onStreamFinished: widget.show(text)
    }

    Timer {
        interval: widget.interval
        running: !widget.watch
        repeat: true
        onTriggered: process.running = true
    }

    Timer {
        id: refresh
        interval: 400
        onTriggered: process.running = true
    }

    // waybar's restart-interval: a watcher that ends starts again.
    Timer {
        id: restart
        interval: 5000
        onTriggered: process.running = true
    }
}
