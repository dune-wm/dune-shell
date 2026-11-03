import QtQuick
import Quickshell
import Quickshell.Wayland

// A corner of a monitor (or the middle of its top or bottom edge). While hidden it is a
// thin transparent strip on the edge; when the cursor rests there it grows into its
// content, and shrinks back once the cursor has left it. It reserves no space and takes
// the keyboard only when `takesKeyboard` and opened by its key.
PanelWindow {
    id: corner

    // "bottom" or "top".
    property string edge: "bottom"
    // "left", "right" or "center".
    property string side: "left"
    // How tall the content is when open (pills are; a minimap is taller).
    property int contentHeight: Theme.pillHeight
    // What the corner shows when it is open.
    default property alias content: holder.data

    property bool open: false
    // Opened by its key (`toggle`), not the cursor: with `takesKeyboard` it has the keyboard
    // until it closes.
    property bool keyed: false
    property bool takesKeyboard: false
    // Keeps the corner open while set (a menu of it is open), whatever the cursor does.
    property bool held: false
    // Room kept above the pill for what comes and goes with the cursor (tooltips). The
    // open window never changes size under the cursor: dune would move the surface
    // before it is redrawn, the cursor would fall off the widget and the corner flicker.
    property int reserve: 0
    // The same for the width: the open window is at least this wide, so a tooltip wider
    // than the pill fits without it growing.
    property int reserveWidth: 0
    // How long it stays open after the cursor leaves it.
    property int hideDelay: Theme.hideDelay
    // How wide the strip on the edge that wakes it up is.
    property int triggerWidth: Theme.triggerWidth

    onHeldChanged: {
        if (!held && open && !hover.hovered)
            hideTimer.start();
    }

    // Fades and slides the content back into the edge, then shrinks the corner. A click
    // that is done with the corner (a window clicked outside the minimap) closes it at once.
    // `picked` is set when a click asked for it: then the cursor coming back (dune can send
    // it again when the view moves under it) does not bring the corner back.
    property bool picked: false
    // The cursor is on what the corner shows.
    readonly property bool hovered: hover.hovered

    function dismiss(byClick) {
        showTimer.stop();
        hideTimer.stop();
        keyed = false;
        if (byClick && open)
            picked = true;
        if (open && !closeAnimation.running) {
            openAnimation.stop();
            closeAnimation.start();
        }
    }

    // Opened or closed by a key (no cursor on it): it stays until the key comes again, a
    // window takes the focus, or the cursor comes and leaves.
    function toggle() {
        if (open && !closeAnimation.running) {
            dismiss(true);
        } else {
            showTimer.stop();
            hideTimer.stop();
            keyed = true;
            if (open) {
                closeAnimation.stop();
                openAnimation.start();
            } else {
                open = true;
            }
        }
    }

    // Opened by something that changed (the volume), not the cursor: it stays `duration`
    // ms after the last call, longer if the cursor comes onto it.
    function peek(duration) {
        showTimer.stop();
        hideTimer.stop();
        if (!open) {
            open = true;
        } else if (closeAnimation.running) {
            closeAnimation.stop();
            openAnimation.start();
        }
        peekTimer.interval = duration;
        peekTimer.restart();
    }

    Timer {
        id: peekTimer
        onTriggered: {
            if (!hover.hovered && !corner.held)
                corner.dismiss();
        }
    }

    onOpenChanged: {
        if (open) {
            closeAnimation.stop();
            openAnimation.start();
        }
    }

    anchors {
        bottom: edge === "bottom"
        top: edge === "top"
        left: side === "left"
        right: side === "right"
    }
    // Right on the screen edge even where another layer (a bar) reserves space there,
    // since the edge is what stops the cursor.
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "dune-shell-corner"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: takesKeyboard && keyed && open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    implicitWidth: open ? Math.max(holder.implicitWidth + 2 * Theme.margin, triggerWidth, reserveWidth) : triggerWidth
    implicitHeight: open ? contentHeight + 2 * Theme.margin + reserve : Theme.triggerHeight

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
                else if (closeAnimation.running && !corner.picked) {
                    // Back before it was gone: it comes back from where it is.
                    closeAnimation.stop();
                    openAnimation.start();
                }
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
        interval: corner.hideDelay
        onTriggered: {
            if (!corner.held)
                corner.dismiss();
        }
    }

    // How far the content travels into the edge as it goes.
    readonly property real slideDistance: edge === "bottom" ? 12 : -12

    ParallelAnimation {
        id: openAnimation
        NumberAnimation {
            target: holder
            property: "opacity"
            to: 1
            duration: Theme.openDuration
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: holder
            property: "scale"
            to: 1
            duration: Theme.openDuration
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: slide
            property: "y"
            to: 0
            duration: Theme.openDuration
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: closeAnimation
        ParallelAnimation {
            NumberAnimation {
                target: holder
                property: "opacity"
                to: 0
                duration: Theme.closeDuration
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: holder
                property: "scale"
                to: 0.94
                duration: Theme.closeDuration
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: slide
                property: "y"
                to: corner.slideDistance
                duration: Theme.closeDuration
                easing.type: Easing.InCubic
            }
        }
        ScriptAction {
            script: {
                corner.open = false;
                corner.picked = false;
                corner.keyed = false;
            }
        }
    }

    Item {
        id: holder
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        x: corner.side === "left" ? Theme.margin
            : corner.side === "right" ? corner.width - width - Theme.margin
            : (corner.width - width) / 2
        y: corner.edge === "bottom" ? corner.height - height - Theme.margin : Theme.margin
        width: implicitWidth
        height: implicitHeight
        visible: corner.open
        // Driven by the open and close animations, which start from here.
        opacity: 0
        scale: 0.94
        transformOrigin: corner.edge === "bottom" ? Item.Bottom : Item.Top
        transform: Translate {
            id: slide
            y: corner.slideDistance
        }
    }
}
