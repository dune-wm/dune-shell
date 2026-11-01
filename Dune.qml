pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// What dune tells through `dune events`: its windows, the focused one and the strip of
// tiles each monitor shows. The stream starts with the current state, so a restart of
// dune rebuilds everything.
Singleton {
    id: dune

    // Tile -> { app_id, title }.
    property var windows: ({})
    property int focused: -1
    // Output name -> { view, width, height, tiles: [{ tile, x, y, w, h }] } (see dune's
    // src/events.rs).
    property var strips: ({})
    // The folder dune keeps a PNG of each tile in (TILE.png), redrawn while it changes;
    // empty when dune does not.
    readonly property string thumbnails: Quickshell.env("DUNE_THUMBNAILS") ?? ""

    // dune's `minimap` key (Mod+a): show or hide the minimap of that monitor.
    signal minimapAsked(string output)

    function goTo(tile) {
        Quickshell.execDetached(["dune", "goto", String(tile)]);
    }

    function handle(line) {
        let event;
        try {
            event = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (event.event === "minimap") {
            dune.minimapAsked(event.output);
        } else if (event.event === "strip") {
            const next = Object.assign({}, strips);
            next[event.output] = event;
            strips = next;
        } else if (event.event === "output" && event.change === "removed") {
            const next = Object.assign({}, strips);
            delete next[event.output];
            strips = next;
        } else if (event.event === "window") {
            const next = Object.assign({}, windows);
            if (event.change === "close")
                delete next[event.tile];
            else
                next[event.tile] = { app_id: event.app_id, title: event.title };
            windows = next;
            if (event.change === "focus")
                focused = event.tile;
            else if (event.change === "close" && event.tile === focused)
                focused = -1;
        }
    }

    Process {
        id: events
        command: ["dune", "events"]
        running: true
        stdout: SplitParser {
            onRead: line => dune.handle(line)
        }
        // Every kind (none named): a dune without `minimap` events still works with it.
        // dune went away (or restarted): start over once it is back.
        onExited: {
            dune.windows = ({});
            dune.focused = -1;
            dune.strips = ({});
            retry.start();
        }
    }

    Timer {
        id: retry
        interval: 2000
        onTriggered: events.running = true
    }
}
