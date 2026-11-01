import QtQuick
import Quickshell
import Quickshell.Io

// The daily log: how many entries today, and a click opens them over the corner with a
// line to add one. The arrows (or the wheel) go to the days before that have a log, a
// click on the date comes back to today. An entry is a line `[HH:mm]  message` in `<logDir>/YYYY-MM-DD.log`,
// the format the old timer kept.
Widget {
    id: logWidget

    // Above the pill (bottom corners) or under it (top ones).
    property string edge: "bottom"

    readonly property bool menuOpen: popup.visible

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: Theme.logDir.replace(/^~(?=\/|$)/, home)
    readonly property string fileName: today + ".log"
    readonly property var entries: view.loaded ? view.text().split("\n").filter(line => line.trim() !== "") : []
    property string error: ""

    // The days with a log, oldest first ("yyyy-MM-dd"), read when the popup opens; and
    // the one the popup shows, "" for today.
    property var days: []
    property string shownDay: ""
    readonly property string today: Qt.formatDate(clock.date, "yyyy-MM-dd")
    readonly property bool isToday: shownDay === "" || shownDay === today
    readonly property var shownEntries: isToday ? entries
        : dayView.loaded ? dayView.text().split("\n").filter(line => line.trim() !== "") : []

    text: "󰠮 " + entries.length
    color: entries.length ? Theme.text : Theme.muted
    tooltip: popup.visible ? "" : summary()

    onClicked: button => {
        if (button === Qt.LeftButton)
            popup.visible = !popup.visible;
    }
    onScrolled: up => {
        if (popup.visible)
            step(up ? -1 : 1);
    }

    // Today and the days that have a log, in order.
    function allDays() {
        return days.includes(today) ? days : [...days, today];
    }

    // To the day with a log before (-1) or after (1) the one shown.
    function step(by) {
        const all = allDays();
        const at = all.indexOf(isToday ? today : shownDay);
        const to = Math.max(0, Math.min(all.length - 1, at + by));
        shownDay = all[to] === today ? "" : all[to];
    }

    function dateOf(day) {
        const [y, m, d] = day.split("-").map(Number);
        return new Date(y, m - 1, d);
    }

    function clip(line, size) {
        return line.length > size ? line.slice(0, size - 1) + "…" : line;
    }

    // The corner's hint has room for nine lines: the day and the last eight entries (or
    // seven and how many came before).
    function summary() {
        const day = "Log · " + Qt.formatDate(clock.date, "ddd d MMM");
        if (!entries.length)
            return day + " · nothing yet";
        const shown = entries.length > 8 ? entries.slice(-7) : entries;
        const lines = [day];
        if (entries.length > 8)
            lines.push("  + " + (entries.length - 7) + " earlier");
        for (const entry of shown)
            lines.push("  " + clip(entry, 80));
        return lines.join("\n");
    }

    function write(input) {
        const message = input.trim().replace(/\s*\n\s*/g, " ");
        if (message === "")
            return;
        writer.command = ["sh", "-c", 'mkdir -p "$1" && printf "%s\\n" "$3" >> "$1/$2"', "sh", dir, fileName,
            "[" + Qt.formatTime(new Date(), "HH:mm") + "]  " + message];
        writer.running = true;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    FileView {
        id: view
        path: logWidget.dir + "/" + logWidget.fileName
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }

    FileView {
        id: dayView
        path: logWidget.isToday ? "" : logWidget.dir + "/" + logWidget.shownDay + ".log"
        printErrors: false
    }

    // The log files there are, for the arrows.
    Process {
        id: lister
        command: ["ls", "-1", logWidget.dir]
        stdout: StdioCollector {
            onStreamFinished: logWidget.days = text.split("\n")
                .filter(name => /^\d{4}-\d\d-\d\d\.log$/.test(name))
                .map(name => name.slice(0, 10))
                .sort()
        }
    }

    Process {
        id: writer
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") logWidget.error = text.trim().split("\n").pop()
        }
        onStarted: logWidget.error = ""
        onExited: code => {
            if (code !== 0 && logWidget.error === "")
                logWidget.error = "exit code " + code;
            // The file may be new: watching starts once it is there.
            view.reload();
        }
    }

    PopupWindow {
        id: popup

        readonly property bool below: logWidget.edge === "top"

        // Its right side on the widget's, growing to the left; over the pill at the
        // bottom of the monitor, under it at the top.
        anchor.item: logWidget
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
                logWidget.shownDay = "";
                lister.running = true;
                entry.text = "";
                entry.focusInput();
                list.positionViewAtEnd();
            }
        }

        Rectangle {
            id: card

            readonly property int innerWidth: 420
            readonly property int row: Theme.fontSize + 8

            implicitWidth: innerWidth + 2 * Theme.padding
            implicitHeight: content.implicitHeight + 2 * Theme.padding
            radius: Theme.radius
            color: Theme.background
            border.color: Theme.surface
            border.width: 1

            WheelHandler {
                onWheel: event => logWidget.step(event.angleDelta.y > 0 ? -1 : 1)
            }

            // The keys while the field is away (another day shown): the arrows go through
            // the days, Escape closes.
            Item {
                id: keys
                Keys.onLeftPressed: logWidget.step(-1)
                Keys.onRightPressed: logWidget.step(1)
                Keys.onEscapePressed: popup.visible = false
            }

            Connections {
                target: logWidget
                function onIsTodayChanged() {
                    if (logWidget.isToday)
                        entry.focusInput();
                    else
                        keys.forceActiveFocus();
                }
            }

            Column {
                id: content
                x: Theme.padding
                y: Theme.padding
                width: card.innerWidth
                spacing: Theme.margin

                // The day shown, between the arrows.
                Item {
                    width: parent.width
                    height: card.row + 4

                    readonly property var all: logWidget.allDays()
                    readonly property int at: all.indexOf(logWidget.isToday ? logWidget.today : logWidget.shownDay)

                    Label {
                        id: back
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰅁"
                        color: parent.at <= 0 ? Theme.surface : backArea.containsMouse ? Theme.accent : Theme.text

                        MouseArea {
                            id: backArea
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: logWidget.step(-1)
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: {
                            const date = logWidget.isToday ? clock.date : logWidget.dateOf(logWidget.shownDay);
                            const name = Qt.formatDate(date, "dddd d MMMM" + (date.getFullYear() !== clock.date.getFullYear() ? " yyyy" : ""));
                            return (logWidget.isToday ? "Today · " : "") + name.charAt(0).toUpperCase() + name.slice(1);
                        }
                        font.bold: true
                        color: homeArea.containsMouse && !logWidget.isToday ? Theme.accent : Theme.text

                        MouseArea {
                            id: homeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: logWidget.isToday ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: logWidget.shownDay = ""
                        }
                    }

                    Label {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰅂"
                        color: parent.at >= parent.all.length - 1 ? Theme.surface : nextArea.containsMouse ? Theme.accent : Theme.text

                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: logWidget.step(1)
                        }
                    }
                }

                Label {
                    visible: logWidget.shownEntries.length === 0
                    text: logWidget.isToday ? "Nothing yet today" : "Nothing that day"
                    color: Theme.muted
                }

                ListView {
                    id: list
                    visible: count > 0
                    width: parent.width
                    height: Math.min(count, 12) * card.row
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: logWidget.shownEntries
                    // The latest entries are the ones that matter.
                    onCountChanged: positionViewAtEnd()

                    delegate: Label {
                        required property string modelData
                        width: list.width
                        height: card.row
                        verticalAlignment: Text.AlignVCenter
                        text: modelData
                    }
                }

                // Entries go to today: on another day the field waits.
                Field {
                    id: entry
                    visible: logWidget.isToday
                    width: parent.width
                    placeholder: "What are you on?"
                    onAccepted: value => logWidget.write(value)
                    onEscaped: popup.visible = false
                }

                Label {
                    visible: logWidget.error !== ""
                    width: parent.width
                    text: logWidget.error
                    color: Theme.alert
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
