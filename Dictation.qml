import QtQuick
import Quickshell
import Quickshell.Io

// Hex's dictation language (dune-voice's Shift). A click opens the languages over it; the
// one picked is marked at once and shows it is switching (Hex takes 1.5–3 s) until Hex
// has it, then the list closes. A right click is English again (Mod's phrases need it).
// Hidden while Hex is not running.
Widget {
    id: dictation

    // The list is open, so the corner has to stay.
    readonly property bool menuOpen: popup.visible
    readonly property var languages: [
        { code: "en", name: "English" },
        { code: "es", name: "Español" },
        { code: "it", name: "Italiano" },
    ]

    // What Hex has now ("": not running), and the one asked for until it has it.
    property string current: ""
    property string pending: ""

    readonly property string shown: pending !== "" ? pending : current

    text: "󰍬 " + shown.toUpperCase()
    color: pending !== "" ? Theme.muted : Theme.text
    visible: current !== ""
    tooltip: popup.visible ? "" : "Dictation: " + nameOf(shown)
        + (pending !== "" ? " (switching…)" : "") + "\nclick: choose · right click: English"

    function nameOf(code) {
        const found = languages.find(l => l.code === code);
        return found ? found.name : code;
    }

    function choose(code) {
        if (code === current && pending === "") {
            popup.visible = false;
            return;
        }
        pending = code;
        giveUp.restart();
        Quickshell.execDetached(["dune-voice", "language", code]);
        status.running = true;
    }

    onClicked: button => {
        if (button === Qt.LeftButton)
            popup.visible = !popup.visible;
        else if (button === Qt.RightButton)
            choose("en");
    }

    Process {
        id: status
        command: ["hex", "status", "--json"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let language = "";
                try {
                    language = JSON.parse(text).model.language ?? "";
                } catch (e) {}
                dictation.current = language;
                if (dictation.pending !== "" && language === dictation.pending) {
                    dictation.pending = "";
                    giveUp.stop();
                    close.restart();
                }
            }
        }
    }

    // Every few seconds; often while switching, so the change shows as soon as Hex has it.
    Timer {
        interval: dictation.pending !== "" ? 300 : 3000
        running: true
        repeat: true
        onTriggered: status.running = true
    }

    // Hex did not take it (dune-voice notifies why): back to what it has.
    Timer {
        id: giveUp
        interval: 8000
        onTriggered: dictation.pending = ""
    }

    // A moment to see it landed before the list goes.
    Timer {
        id: close
        interval: 400
        onTriggered: popup.visible = false
    }

    PopupWindow {
        id: popup

        // Over the widget, growing up and to the left like the calendar's.
        anchor.item: dictation
        anchor.edges: Edges.Top | Edges.Right
        anchor.gravity: Edges.Top | Edges.Left
        anchor.margins.top: -Theme.padding - Theme.margin
        anchor.margins.right: -Theme.padding
        grabFocus: true
        color: "transparent"
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight

        Rectangle {
            id: card

            implicitWidth: list.implicitWidth + 2 * Theme.padding
            implicitHeight: list.implicitHeight + 2 * Theme.padding
            radius: Theme.radius
            color: Theme.background
            border.color: Theme.surface
            border.width: 1

            Column {
                id: list
                x: Theme.padding
                y: Theme.padding
                spacing: Theme.margin / 2

                Repeater {
                    model: dictation.languages

                    Rectangle {
                        id: row
                        required property var modelData
                        readonly property bool chosen: modelData.code === dictation.shown
                        readonly property bool switching: modelData.code === dictation.pending

                        width: 180
                        height: 34
                        radius: Theme.radius
                        color: chosen ? Theme.surface : pick.containsMouse ? Qt.darker(Theme.surface, 1.4) : "transparent"

                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.padding
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.name
                            color: row.chosen ? Theme.accent : Theme.text
                        }

                        // Switching: a dot that pulses until Hex has it; there: a check.
                        Label {
                            id: mark
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.padding
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.chosen
                            text: row.switching ? "●" : "󰄬"
                            color: Theme.accent

                            SequentialAnimation on opacity {
                                running: row.switching
                                loops: Animation.Infinite
                                onStopped: mark.opacity = 1
                                NumberAnimation { to: 0.2; duration: 450 }
                                NumberAnimation { to: 1; duration: 450 }
                            }
                        }

                        MouseArea {
                            id: pick
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dictation.choose(row.modelData.code)
                        }
                    }
                }
            }
        }
    }
}
