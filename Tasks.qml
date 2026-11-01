import QtQuick
import Quickshell
import Quickshell.Io

// Taskwarrior, from the bar: the mode and how many tasks are pending, and a click opens
// them over the corner, most urgent first. The circle of a task completes it, the field
// under them adds one (taskwarrior's modifiers kept: "pay rent due:friday +home"), and the
// mode at the top switches between the data dirs of `taskModes` (a right click too).
Widget {
    id: tasks

    // Above the pill (bottom corners) or under it (top ones).
    property string edge: "bottom"

    readonly property bool menuOpen: popup.visible

    readonly property string home: Quickshell.env("HOME")
    readonly property var modes: {
        const modes = Theme.taskModes;
        const out = {};
        for (const name in modes)
            out[name] = String(modes[name]).replace(/^~(?=\/|$)/, home);
        return out;
    }
    readonly property var modeNames: Object.keys(modes)
    // What the state file says, if it is still one of the modes; else the first one.
    property string savedMode: ""
    readonly property string mode: modes[savedMode] !== undefined ? savedMode : (modeNames[0] ?? "")
    readonly property string dataDir: modes[mode] ?? ""
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/dune"

    // The pending tasks (taskwarrior's export), most urgent first; null when it failed.
    property var list: []
    readonly property bool failed: list === null
    // The last command that went wrong, shown in the popup until the next one.
    property string error: ""

    readonly property string label: mode.charAt(0).toUpperCase() + mode.slice(1)

    text: "󰄲 " + label + " " + (failed ? "?" : list.length)
    color: failed ? Theme.alert : Theme.text
    tooltip: popup.visible ? "" : summary()

    onClicked: button => {
        if (button === Qt.LeftButton) {
            popup.visible = !popup.visible;
            if (popup.visible)
                load();
        } else if (button === Qt.RightButton) {
            toggle();
        }
    }

    // taskwarrior with the mode's data dir and nothing but what was asked printed. Hooks
    // off: the ones there only refreshed the old bars.
    function task(args) {
        return ["task", "rc.data.location=" + dataDir, "rc.hooks=off", "rc.confirmation=off", "rc.verbose=nothing", ...args];
    }

    function describe(item) {
        const meta = [];
        if (item.project)
            meta.push(item.project);
        if (item.due)
            meta.push(dueIn(item.due));
        return item.description + (meta.length ? "  · " + meta.join(" · ") : "");
    }

    // When a task is due, from today: "overdue", "today", "tomorrow", the weekday within
    // the week, else the date.
    function dueIn(value) {
        const due = parseDate(value);
        const day = date => new Date(date.getFullYear(), date.getMonth(), date.getDate());
        const days = Math.round((day(due) - day(clock.date)) / 86400000);
        if (due < clock.date && days <= 0)
            return days < 0 ? "overdue " + -days + "d" : "overdue";
        if (days === 0)
            return "due today " + Qt.formatTime(due, "HH:mm");
        if (days === 1)
            return "due tomorrow";
        if (days < 7)
            return "due " + Qt.locale().dayName(due.getDay(), Locale.ShortFormat);
        return "due " + Qt.formatDate(due, "d MMM");
    }

    function clip(line, size) {
        return line.length > size ? line.slice(0, size - 1) + "…" : line;
    }

    // The corner's hint has room for nine lines: the count, the seven most urgent tasks
    // and how many more.
    function summary() {
        if (failed)
            return label + " · could not read " + dataDir;
        const lines = [label + " · " + (list.length ? list.length + " pending" : "nothing pending")];
        const shown = list.length > 8 ? 7 : 8;
        for (const item of list.slice(0, shown))
            lines.push("  " + (item.due && dueIn(item.due).startsWith("overdue") ? "! " : "• ") + clip(describe(item), 80));
        if (list.length > shown)
            lines.push("  + " + (list.length - shown) + " more");
        return lines.join("\n");
    }

    // taskwarrior's dates: 20261101T093110Z.
    function parseDate(value) {
        const m = /^(\d{4})(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)Z$/.exec(value);
        return m ? new Date(Date.UTC(+m[1], m[2] - 1, +m[3], +m[4], +m[5], +m[6])) : new Date(value);
    }

    function load() {
        if (dataDir === "")
            return;
        if (exporter.running)
            reloadAgain.restart();
        else
            exporter.running = true;
    }

    function toggle() {
        if (modeNames.length < 2)
            return;
        const next = modeNames[(modeNames.indexOf(mode) + 1) % modeNames.length];
        savedMode = next;
        enqueue(["sh", "-c", 'mkdir -p "$1" && printf "%s\\n" "$2" > "$1/task-mode"', "sh", stateDir, next], false);
    }

    function add(input) {
        const words = input.trim().split(/\s+/).filter(word => word !== "");
        if (words.length)
            enqueue(task(["add", ...words]), true);
    }

    function complete(uuid) {
        // The uuid, not the id: ids shift when tasks are added or completed elsewhere.
        if (/^[0-9a-f-]{36}$/.test(uuid))
            enqueue(task([uuid, "done"]), true);
    }

    // One command at a time, in the order they were asked for.
    property var queue: []

    function enqueue(command, reloads) {
        queue = [...queue, { command, reloads }];
        next();
    }

    function next() {
        if (runner.running || queue.length === 0)
            return;
        const job = queue[0];
        queue = queue.slice(1);
        runner.reloads = job.reloads;
        runner.command = job.command;
        runner.running = true;
    }

    onDataDirChanged: load()
    Component.onCompleted: load()

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Process {
        id: exporter
        command: tasks.task(["status:pending", "export"])
        // A failed run writes nothing to stdout, which does not parse either.
        stdout: StdioCollector {
            onStreamFinished: {
                let parsed = null;
                try {
                    parsed = JSON.parse(text);
                } catch (e) {}
                tasks.list = Array.isArray(parsed)
                    ? parsed.sort((a, b) => (b.urgency ?? 0) - (a.urgency ?? 0))
                    : null;
            }
        }
    }

    // A reload asked for while one was running: once more when it is done.
    Timer {
        id: reloadAgain
        interval: 200
        onTriggered: tasks.load()
    }

    Process {
        id: runner
        property bool reloads: false
        stderr: StdioCollector {
            // Its last line, the one that says what went wrong.
            onStreamFinished: if (text.trim() !== "") tasks.error = text.trim().split("\n").pop()
        }
        onStarted: tasks.error = ""
        onExited: code => {
            if (code !== 0 && tasks.error === "")
                tasks.error = "exit code " + code;
            if (reloads)
                tasks.load();
            tasks.next();
        }
    }

    // Tasks changed elsewhere (a terminal, a sync) show up without waiting for the poll.
    FileView {
        path: tasks.dataDir === "" ? "" : tasks.dataDir + "/taskchampion.sqlite3"
        watchChanges: true
        printErrors: false
        blockLoading: false
        onFileChanged: settle.restart()
    }

    Timer {
        id: settle
        interval: 300
        onTriggered: tasks.load()
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: tasks.load()
    }

    FileView {
        path: tasks.stateDir + "/task-mode"
        printErrors: false
        onLoaded: tasks.savedMode = text().trim()
    }

    PopupWindow {
        id: popup

        readonly property bool below: tasks.edge === "top"

        // Its right side on the widget's, growing to the left; over the pill at the
        // bottom of the monitor, under it at the top.
        anchor.item: tasks
        anchor.edges: (below ? Edges.Bottom : Edges.Top) | Edges.Right
        anchor.gravity: (below ? Edges.Bottom : Edges.Top) | Edges.Left
        anchor.margins.top: below ? 0 : -Theme.padding - Theme.margin
        anchor.margins.bottom: below ? -Theme.padding - Theme.margin : 0
        anchor.margins.right: -Theme.padding
        grabFocus: true
        color: "transparent"
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight

        onVisibleChanged: {
            if (visible) {
                newTask.text = "";
                newTask.focusInput();
            }
        }

        Rectangle {
            id: card

            readonly property int innerWidth: 420
            readonly property int row: Theme.fontSize + 14

            implicitWidth: innerWidth + 2 * Theme.padding
            implicitHeight: content.implicitHeight + 2 * Theme.padding
            radius: Theme.radius
            color: Theme.background
            border.color: Theme.surface
            border.width: 1

            Column {
                id: content
                x: Theme.padding
                y: Theme.padding
                width: card.innerWidth
                spacing: Theme.margin

                // The modes, the current one lit; a click picks another.
                Row {
                    spacing: Theme.itemSpacing

                    Repeater {
                        model: tasks.modeNames

                        delegate: Label {
                            required property string modelData
                            readonly property bool current: modelData === tasks.mode
                            text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                            font.bold: current
                            color: current ? Theme.accent : pick.containsMouse ? Theme.text : Theme.muted

                            MouseArea {
                                id: pick
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (!parent.current) tasks.toggle()
                            }
                        }
                    }
                }

                Label {
                    visible: tasks.failed || tasks.list.length === 0
                    text: tasks.failed ? "could not read " + tasks.dataDir : "Nothing pending"
                    color: tasks.failed ? Theme.alert : Theme.muted
                }

                ListView {
                    id: listView
                    visible: !tasks.failed && count > 0
                    width: parent.width
                    height: Math.min(count, 10) * card.row
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: tasks.failed ? [] : tasks.list

                    delegate: Item {
                        id: entry
                        required property var modelData
                        width: listView.width
                        height: card.row

                        Label {
                            id: check
                            anchors.verticalCenter: parent.verticalCenter
                            width: Theme.fontSize + 8
                            text: done.containsMouse ? "󰄲" : "󰄱"
                            color: done.containsMouse ? Theme.accent : Theme.muted

                            MouseArea {
                                id: done
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: tasks.complete(entry.modelData.uuid)
                            }
                        }

                        Label {
                            anchors.left: check.right
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: tasks.describe(entry.modelData)
                            color: done.containsMouse ? Theme.muted : Theme.text
                            font.strikeout: done.containsMouse
                        }
                    }
                }

                Field {
                    id: newTask
                    width: parent.width
                    placeholder: "New task (due:, +tag, project: work)"
                    onAccepted: value => tasks.add(value)
                    onEscaped: popup.visible = false
                }

                Label {
                    visible: tasks.error !== ""
                    width: parent.width
                    text: tasks.error
                    color: Theme.alert
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
