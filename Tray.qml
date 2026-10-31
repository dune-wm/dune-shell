import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

// The system tray: click activates an item, right click opens its menu (upwards, since
// the corner is at the bottom).
Row {
    id: tray

    // An item's menu is open, so the corner has to stay.
    readonly property bool menuOpen: {
        for (let i = 0; i < children.length; i++)
            if (children[i].menuOpen)
                return true;
        return false;
    }
    readonly property string hint: {
        for (let i = 0; i < children.length; i++)
            if (children[i].hovered)
                return children[i].tooltip;
        return "";
    }

    spacing: Theme.padding / 2

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: entry

            required property SystemTrayItem modelData
            readonly property bool menuOpen: menu.visible
            readonly property bool hovered: mouse.containsMouse
            readonly property string tooltip: modelData.tooltipTitle || modelData.title

            implicitWidth: Theme.fontSize + 4
            implicitHeight: Theme.fontSize + 4

            IconImage {
                anchors.fill: parent
                source: entry.modelData.icon
            }

            QsMenuAnchor {
                id: menu
                menu: entry.modelData.menu
                anchor.item: entry
                anchor.edges: Edges.Top
                anchor.gravity: Edges.Top
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: event => {
                    const item = entry.modelData;
                    if (event.button === Qt.RightButton || (event.button === Qt.LeftButton && item.onlyMenu)) {
                        if (item.hasMenu)
                            menu.open();
                    } else if (event.button === Qt.MiddleButton) {
                        item.secondaryActivate();
                    } else {
                        item.activate();
                    }
                }
                onWheel: event => entry.modelData.scroll(event.angleDelta.y, false)
            }
        }
    }
}
