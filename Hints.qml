import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// The words dune-a11y put on what can be clicked around the pointer (`dune-a11y hints`, or
// saying "hints"): said, that thing is clicked. It only draws: no keyboard, and clicks go
// through. They go after 15 s (dune-a11y's OPEN_FOR) or when the file says nothing.
PanelWindow {
    id: overlay

    readonly property string statePath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/dune-hints.json"
    property var labels: []

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: labels.length > 0

    WlrLayershell.namespace: "dune-shell-hints"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {}

    function read(text) {
        let state = {};
        try {
            state = JSON.parse(text);
        } catch (e) {}
        const fresh = Date.now() / 1000 - (state.at ?? 0) < 15;
        overlay.labels = state.output === overlay.screen.name && fresh ? (state.hints ?? []) : [];
        if (overlay.labels.length > 0)
            expiry.restart();
    }

    FileView {
        path: overlay.statePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: overlay.read(text())
        onLoadFailed: overlay.labels = []
    }

    Timer {
        id: expiry
        interval: 15000
        onTriggered: overlay.labels = []
    }

    Repeater {
        model: overlay.labels

        delegate: Item {
            required property var modelData

            x: modelData.x
            y: modelData.y
            width: modelData.w
            height: modelData.h

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Theme.accent
                border.width: 1
                radius: 3
            }

            Rectangle {
                x: 2
                y: Math.max(2 - parent.y, -4)
                width: word.implicitWidth + 10
                height: word.implicitHeight + 4
                radius: 4
                color: Theme.accent

                Text {
                    id: word
                    anchors.centerIn: parent
                    text: modelData.word
                    color: Theme.inverse
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }
            }
        }
    }
}
