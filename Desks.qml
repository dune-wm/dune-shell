import QtQuick
import Quickshell
import Quickshell.WindowManager

// The desks of a monitor, from dune's ext-workspace: click shows one, right click locks
// or unlocks it. Desks dune hides (empty ones) are left out.
Row {
    id: desks

    required property ShellScreen screen

    spacing: 2

    Repeater {
        model: WindowManager.screenProjection(desks.screen).windowsets.filter(set => set.shouldDisplay)

        delegate: Rectangle {
            id: desk

            required property Windowset modelData

            implicitWidth: Math.max(label.implicitWidth + Theme.padding, implicitHeight)
            implicitHeight: label.implicitHeight + 4
            radius: Theme.radius / 2
            color: modelData.urgent ? Theme.alert
                : modelData.active ? Theme.accent
                : mouse.containsMouse ? Theme.surface : "transparent"

            Label {
                id: label
                anchors.centerIn: parent
                text: desk.modelData.name
                color: desk.modelData.active || desk.modelData.urgent ? Theme.inverse
                    : mouse.containsMouse ? Theme.text : Theme.muted
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: event => {
                    if (event.button === Qt.RightButton)
                        desk.modelData.deactivate();
                    else
                        desk.modelData.activate();
                }
            }
        }
    }
}
