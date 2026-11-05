//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Io

// Each monitor gets its two bottom corners, its dock and desks on the left and every
// widget on the right (on the main one, split with its top right corner, see
// Theme.mainOutput), a minimap of its strip in the middle of the top edge (or of the
// bottom one, see Theme.minimapEdges), and the spoken labels of dune-a11y's hints.
ShellRoot {
    // The look of dune's tiles, set by hand: `qs -c dune ipc call settings toggle`.
    Settings {
        id: settingsWindow
    }

    IpcHandler {
        target: "settings"

        function toggle(): void {
            settingsWindow.toggle();
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Scope {
                id: monitor
                required property ShellScreen modelData
                readonly property bool main: modelData.name === Theme.mainOutput

                Corner {
                    id: dockCorner
                    screen: monitor.modelData
                    side: "left"
                    hideDelay: 500
                    // The dock unfolds from above this pill: it stays while the dock does.
                    held: dock.shown

                    Pill {
                        // How many entries the dock of this monitor holds; a click opens it.
                        Widget {
                            readonly property int count: Dune.docks[monitor.modelData.name]?.entries?.length ?? 0
                            text: "󱂩 " + count
                            color: count > 0 ? Theme.text : Theme.muted
                            onClicked: dock.toggle()
                        }
                        Separator {}
                        Desks {
                            screen: monitor.modelData
                        }
                    }
                }

                Hints {
                    screen: monitor.modelData
                }

                Dock {
                    id: dock
                    screen: monitor.modelData
                    // Opened by the key, the pill it rises from comes too; it goes with the
                    // corner's usual delay once the dock has folded.
                    onShownChanged: {
                        if (shown)
                            dockCorner.peek(dockCorner.hideDelay);
                    }

                    Connections {
                        target: Dune
                        function onDockAsked(output) {
                            if (output === monitor.modelData.name)
                                dock.toggle();
                        }
                    }
                }

                Corner {
                    id: controlsCorner
                    screen: monitor.modelData
                    side: "right"
                    held: widgets.menuOpen
                    reserve: Theme.hintSpace
                    reserveWidth: Theme.hintWidth + 2 * Theme.margin

                    Widgets {
                        id: widgets
                        part: monitor.main ? "controls" : "all"
                        // On the monitor in use only.
                        onVolumeAdjusted: {
                            if (Dune.activeOutput === monitor.modelData.name)
                                controlsCorner.peek(Theme.volumePeek);
                        }
                    }
                }

                // The main monitor: work and system status in its top right corner.
                Loader {
                    active: monitor.main

                    sourceComponent: Corner {
                        screen: monitor.modelData
                        edge: "top"
                        side: "right"
                        held: statusWidgets.menuOpen
                        reserve: Theme.hintSpace
                        reserveWidth: Theme.hintWidth + 2 * Theme.margin

                        Widgets {
                            id: statusWidgets
                            part: "status"
                            edge: "top"
                        }
                    }
                }

                Corner {
                    id: minimapCorner
                    screen: monitor.modelData
                    edge: Theme.minimapEdges[monitor.modelData.name] ?? "top"
                    side: "center"
                    contentHeight: Theme.minimapHeight
                    hideDelay: Theme.minimapHideDelay
                    triggerWidth: Theme.minimapTriggerWidth
                    takesKeyboard: true

                    Minimap {
                        output: monitor.modelData.name
                        maxWidth: monitor.modelData.width - 4 * Theme.margin
                        onDone: minimapCorner.dismiss(true)
                    }

                    // A click on a window of the screen focuses it: the minimap goes at once
                    // instead of waiting for its delay. A tile picked in the minimap moves the
                    // focus too, but with the cursor still on it the minimap stays; opened by
                    // its key it stays while the arrows (or the voice) move the focus.
                    Connections {
                        target: Dune
                        function onFocusedChanged() {
                            if (!minimapCorner.hovered && !minimapCorner.keyed)
                                minimapCorner.dismiss(true);
                        }
                        function onMinimapAsked(output) {
                            if (output === monitor.modelData.name)
                                minimapCorner.toggle();
                        }
                    }
                }
            }
        }
    }
}
