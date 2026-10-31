import QtQuick
import Quickshell

// Each monitor gets its two bottom corners: its desks and dock on the left, every
// widget on the right.
ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Scope {
                id: monitor
                required property ShellScreen modelData

                Corner {
                    screen: monitor.modelData
                    side: "left"

                    Pill {
                        Desks {
                            screen: monitor.modelData
                        }
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

                    Widgets {
                        id: widgets
                    }
                }
            }
        }
    }
}
