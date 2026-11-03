pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// What dune tells through `dune events`: its windows, the focused one, the strip of
// tiles each monitor shows and what its dock holds. The stream starts with the current state, so a restart of
// dune rebuilds everything.
Singleton {
    id: dune

    // Tile -> { app_id, title }.
    property var windows: ({})
    property int focused: -1
    // Output name -> { view, width, height, tiles: [{ tile, x, y, w, h }] } (see dune's
    // src/events.rs).
    property var strips: ({})
    // Output name -> { entries, scratchpad }: what the dock of each monitor holds, in
    // dune's order (pinned first), and the windows waiting in the scratchpad (the same
    // on every monitor). Each entry is { tile, app_id, title, pinned, tabs }, `tabs` the
    // first tile of each tab of a column ({ tile, app_id, title }), empty for one tile.
    property var docks: ({})
    // The folder dune keeps a PNG of each tile in (TILE.png), redrawn while it changes;
    // empty when dune does not.
    readonly property string thumbnails: Quickshell.env("DUNE_THUMBNAILS") ?? ""

    // dune's `minimap` key (Mod+a): show or hide the minimap of that monitor.
    signal minimapAsked(string output)
    // dune's `dock_show` key (or `dune dock show`): show or hide the dock of that monitor.
    signal dockAsked(string output)

    // The monitor whose strip holds the focused window; the main one when none does.
    readonly property string activeOutput: {
        for (const output in strips) {
            if ((strips[output].tiles ?? []).some(t => t.tile === focused))
                return output;
        }
        return Theme.mainOutput;
    }

    function goTo(tile) {
        Quickshell.execDetached(["dune", "goto", String(tile)]);
    }

    // The dock entry holding `tile` back out, focused (that tab shown when it is a
    // column); a tile in the scratchpad floats out of it.
    function takeFromDock(tile) {
        Quickshell.execDetached(["dune", "dock", "take", String(tile)]);
    }

    // Pins or unpins the dock entry holding `tile`; unpinned it goes to the desktop
    // `output` shows.
    function pinInDock(tile, output) {
        const command = ["dune", "dock", "pin", String(tile)];
        if (output)
            command.push(output);
        Quickshell.execDetached(command);
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
        } else if (event.event === "dock") {
            if (event.change === "toggle") {
                dune.dockAsked(event.output);
            } else if (event.change === "entries") {
                const next = Object.assign({}, docks);
                next[event.output] = { entries: event.entries ?? [], scratchpad: event.scratchpad ?? [] };
                docks = next;
            }
        } else if (event.event === "strip") {
            const next = Object.assign({}, strips);
            next[event.output] = event;
            strips = next;
        } else if (event.event === "output" && event.change === "removed") {
            const next = Object.assign({}, strips);
            delete next[event.output];
            strips = next;
            const nextDocks = Object.assign({}, docks);
            delete nextDocks[event.output];
            docks = nextDocks;
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
            dune.docks = ({});
            retry.start();
        }
    }

    Timer {
        id: retry
        interval: 2000
        onTriggered: events.running = true
    }
}
