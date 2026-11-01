//@ pragma UseQApplication

import QtQuick
import Quickshell

// Each monitor gets its two bottom corners, its desks and dock on the left and every
// widget on the right (on the main one, split with its top right corner, see
// Theme.mainOutput), and a minimap of its strip in the middle of the top edge (or of
// the bottom one, see Theme.minimapEdges).
ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Scope {
                id: monitor
                required property ShellScreen modelData
                readonly property bool main: modelData.name === Theme.mainOutput

                Corner {
                    screen: monitor.modelData
                    side: "left"

                    Pill {
                        Desks {
                            screen: monitor.modelData
                        }
                        Separator {}
                        // The dock of this monitor: dune finds it by waybar's variable.
                        ScriptWidget {
                            exec: "WAYBAR_OUTPUT_NAME=" + monitor.modelData.name + " dune dock watch"
                            watch: true
                            format: "󱂩 {}"
                            colors: ({ empty: Theme.muted })
                            leftClick: "WAYBAR_OUTPUT_NAME=" + monitor.modelData.name + " dune dock show"
                        }
                    }
                }

                Corner {
                    screen: monitor.modelData
                    side: "right"
                    held: widgets.menuOpen
                    reserve: Theme.hintSpace
                    reserveWidth: Theme.hintWidth + 2 * Theme.margin

                    Widgets {
                        id: widgets
                        part: monitor.main ? "controls" : "all"
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

                    Minimap {
                        output: monitor.modelData.name
                        maxWidth: monitor.modelData.width - 4 * Theme.margin
                    }

                    // A click on a window of the screen focuses it: the minimap goes at once
                    // instead of waiting for its delay. A tile picked in the minimap moves the
                    // focus too, but with the cursor still on it the minimap stays.
                    Connections {
                        target: Dune
                        function onFocusedChanged() {
                            if (!minimapCorner.hovered)
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
