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
    // Keeps the corner open while set (a menu of it is open), whatever the cursor does.
    property bool held: false
    // Room kept above the pill for what comes and goes with the cursor (tooltips). The
    // open window never changes size under the cursor: dune would move the surface
    // before it is redrawn, the cursor would fall off the widget and the corner flicker.
    property int reserve: 0

    onHeldChanged: {
        if (!held && open && !hover.hovered)
            hideTimer.start();
    }

    anchors {
        bottom: true
        left: side === "left"
        right: side === "right"
    }
    // Right on the screen edge even where another layer (a bar) reserves space there,
    // since the edge is what stops the cursor.
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "dune-shell-corner"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    implicitWidth: open ? Math.max(holder.implicitWidth + 2 * Theme.margin, Theme.triggerWidth) : Theme.triggerWidth
    implicitHeight: open ? Theme.pillHeight + 2 * Theme.margin + reserve : Theme.triggerHeight

    // Open, only what is drawn takes the cursor; the room kept above it lets it through.
    mask: open ? drawn : null

    Region {
        id: drawn
        item: holder
    }

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
        onTriggered: corner.open = corner.held
    }

    Item {
        id: holder
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        x: corner.side === "left" ? Theme.margin : corner.width - width - Theme.margin
        y: corner.height - height - Theme.margin
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
