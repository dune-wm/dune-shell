import QtQuick

// A whole number from `from` to `to`, dragged along a track or stepped with the wheel;
// `moved` comes on every step, so what it sets shows at once.
Item {
    id: slider

    property int value: 0
    property int from: 0
    property int to: 10
    signal moved(int value)

    function set(v) {
        v = Math.max(from, Math.min(to, Math.round(v)));
        if (v !== value) {
            value = v;
            slider.moved(v);
        }
    }

    implicitWidth: 260
    implicitHeight: 20

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Theme.surface

        Rectangle {
            width: (slider.value - slider.from) / Math.max(1, slider.to - slider.from) * parent.width
            height: parent.height
            radius: 2
            color: Theme.accent
        }
    }

    Rectangle {
        width: 14
        height: 14
        radius: 7
        anchors.verticalCenter: parent.verticalCenter
        x: (slider.value - slider.from) / Math.max(1, slider.to - slider.from) * (parent.width - width)
        color: area.pressed ? Theme.accent : Theme.text
    }

    MouseArea {
        id: area
        anchors.fill: parent
        function at(mouse) {
            slider.set(slider.from + mouse.x / width * (slider.to - slider.from));
        }
        onPressed: mouse => at(mouse)
        onPositionChanged: mouse => at(mouse)
        onWheel: wheel => slider.set(slider.value + (wheel.angleDelta.y > 0 ? 1 : -1))
    }
}
