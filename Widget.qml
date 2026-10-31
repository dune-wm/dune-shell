import QtQuick
import Quickshell

// A piece of a corner: text that runs its shell commands when clicked or scrolled, and
// tells the corner its tooltip while the cursor is on it.
Label {
    id: widget

    property string tooltip: ""
    property string leftClick: ""
    property string middleClick: ""
    property string rightClick: ""
    property string scrollUp: ""
    property string scrollDown: ""
    readonly property bool hovered: mouse.containsMouse

    // For widgets that act in QML rather than through a command.
    signal clicked(int button)
    signal scrolled(bool up)
    // A command ran: what the widget shows may have changed.
    signal ran

    function run(command) {
        if (command === "")
            return;
        Quickshell.execDetached(["sh", "-c", command]);
        ran();
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: event => {
            if (event.button === Qt.LeftButton)
                widget.run(widget.leftClick);
            else if (event.button === Qt.MiddleButton)
                widget.run(widget.middleClick);
            else
                widget.run(widget.rightClick);
            widget.clicked(event.button);
        }
        onWheel: event => {
            const up = event.angleDelta.y > 0;
            widget.run(up ? widget.scrollUp : widget.scrollDown);
            widget.scrolled(up);
        }
    }
}
