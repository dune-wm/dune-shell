import QtQuick
import Quickshell

// Each monitor gets its two bottom corners: the desk it shows and the focused window
// on the left, the time on the right.
ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Scope {
                id: monitor
                required property var modelData

                Corner {
                    screen: monitor.modelData
                    side: "left"

                    Pill {
                        Label {
                            text: "󰍹 " + Dune.deskOf(monitor.modelData.name)
                            color: Theme.accent
                        }
                        Label {
                            visible: Dune.focusedTitle !== ""
                            text: Dune.focusedTitle
                            width: Math.min(implicitWidth, 420)
                        }
                    }
                }

                Corner {
                    screen: monitor.modelData
                    side: "right"

                    Pill {
                        Label {
                            text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
                        }
                    }
                }
            }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
