pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// What dune tells through `dune events`: the desk each monitor shows and the focused
// window. The stream starts with the current state, so a restart rebuilds everything.
Singleton {
    id: dune

    // Output name -> desk number shown on it.
    property var desks: ({})
    property string focusedTitle: ""
    property string focusedApp: ""
    property int focusedTile: -1

    function deskOf(output) {
        return desks[output] ?? 0;
    }

    function handle(line) {
        let event;
        try {
            event = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (event.event === "desktop" && event.change === "focus") {
            const next = Object.assign({}, desks);
            next[event.output] = event.desk;
            desks = next;
        } else if (event.event === "output" && event.change === "removed") {
            const next = Object.assign({}, desks);
            delete next[event.output];
            desks = next;
        } else if (event.event === "window") {
            if (event.change === "focus") {
                focusedTile = event.tile;
                focusedTitle = event.title;
                focusedApp = event.app_id;
            } else if (event.tile === focusedTile) {
                if (event.change === "close") {
                    focusedTile = -1;
                    focusedTitle = "";
                    focusedApp = "";
                } else {
                    focusedTitle = event.title;
                }
            }
        }
    }

    Process {
        id: events
        command: ["dune", "events"]
        running: true
        stdout: SplitParser {
            onRead: line => dune.handle(line)
        }
        // dune went away (or restarted): start over once it is back.
        onExited: {
            dune.desks = ({});
            dune.focusedTile = -1;
            dune.focusedTitle = "";
            dune.focusedApp = "";
            retry.start();
        }
    }

    Timer {
        id: retry
        interval: 2000
        onTriggered: events.running = true
    }
}
