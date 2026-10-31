import QtQuick
import Quickshell
import Quickshell.Wayland

// A bottom corner of a monitor. While hidden it is a thin transparent strip on the
// bottom edge; when the cursor rests there it grows into its content, and shrinks back
// once the cursor has left it. It reserves no space and never takes the keyboard.
PanelWindow {
    id: corner

    // "left" or "right".
    property string side: "left"
    // What the corner shows when it is open.
    default property alias content: holder.data

    property bool open: false

    anchors {
        bottom: true
        left: side === "left"
        right: side === "right"
    }
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.namespace: "dune-shell-corner"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    implicitWidth: open ? Math.max(holder.implicitWidth + 2 * Theme.margin, Theme.triggerWidth) : Theme.triggerWidth
    implicitHeight: open ? holder.implicitHeight + 2 * Theme.margin : Theme.triggerHeight

    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (hovered) {
                hideTimer.stop();
                if (!corner.open)
                    showTimer.start();
            } else {
                showTimer.stop();
                if (corner.open)
                    hideTimer.start();
            }
        }
    }

    Timer {
        id: showTimer
        interval: Theme.showDelay
        onTriggered: corner.open = true
    }

    Timer {
        id: hideTimer
        interval: Theme.hideDelay
        onTriggered: corner.open = false
    }

    Item {
        id: holder
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        x: corner.side === "left" ? Theme.margin : corner.width - width - Theme.margin
        y: Theme.margin
        width: implicitWidth
        height: implicitHeight
        visible: corner.open
        opacity: corner.open ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
    }
}
