import QtQuick

// A color chosen by hand: a square of saturation (across) and brightness (down) for the
// hue of the bar below it. `picked` comes on every move, so what it sets shows at once.
Column {
    id: picker

    // The color shown; set from outside, it moves the marks.
    property color color: "white"
    signal picked(color value)

    property real hue: 0
    property real saturation: 0
    property real brightness: 1

    function follow() {
        // A gray has no hue of its own: keep the one there was.
        if (color.hsvHue >= 0)
            hue = color.hsvHue;
        saturation = color.hsvSaturation;
        brightness = color.hsvValue;
    }
    onColorChanged: {
        if (!square.dragging && !bar.dragging)
            follow();
    }
    Component.onCompleted: follow()

    function emit() {
        picker.picked(Qt.hsva(hue, saturation, brightness, 1));
    }

    spacing: Theme.margin
    width: 260

    Rectangle {
        id: square
        property bool dragging: squareArea.pressed
        width: parent.width
        height: 150
        radius: Theme.radius / 2
        // White into the hue across, then black over it downward.
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "white" }
            GradientStop { position: 1; color: Qt.hsva(picker.hue, 1, 1, 1) }
        }
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: "black" }
            }
        }
        Rectangle {
            width: 12
            height: 12
            radius: 6
            x: picker.saturation * parent.width - width / 2
            y: (1 - picker.brightness) * parent.height - height / 2
            color: "transparent"
            border.color: picker.brightness > 0.5 ? "black" : "white"
            border.width: 2
        }
        MouseArea {
            id: squareArea
            anchors.fill: parent
            function at(mouse) {
                picker.saturation = Math.max(0, Math.min(1, mouse.x / width));
                picker.brightness = 1 - Math.max(0, Math.min(1, mouse.y / height));
                picker.emit();
            }
            onPressed: mouse => at(mouse)
            onPositionChanged: mouse => at(mouse)
        }
    }

    Rectangle {
        id: bar
        property bool dragging: barArea.pressed
        width: parent.width
        height: 14
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0 / 6; color: "#ff0000" }
            GradientStop { position: 1 / 6; color: "#ffff00" }
            GradientStop { position: 2 / 6; color: "#00ff00" }
            GradientStop { position: 3 / 6; color: "#00ffff" }
            GradientStop { position: 4 / 6; color: "#0000ff" }
            GradientStop { position: 5 / 6; color: "#ff00ff" }
            GradientStop { position: 6 / 6; color: "#ff0000" }
        }
        Rectangle {
            width: 6
            height: parent.height + 4
            y: -2
            radius: 3
            x: picker.hue * parent.width - width / 2
            color: "white"
            border.color: "black"
        }
        MouseArea {
            id: barArea
            anchors.fill: parent
            function at(mouse) {
                picker.hue = Math.max(0, Math.min(0.9999, mouse.x / width));
                picker.emit();
            }
            onPressed: mouse => at(mouse)
            onPositionChanged: mouse => at(mouse)
        }
    }
}
