import QtQuick

// A line to type into, for the popups; Enter hands over what it says and empties it.
Rectangle {
    id: field

    property alias text: input.text
    property string placeholder: ""
    // Where Tab goes.
    property Item next: null

    signal accepted(string value)
    signal escaped

    function focusInput() {
        input.forceActiveFocus();
    }

    height: Theme.fontSize + 16
    radius: Theme.radius / 2
    color: Theme.surface
    border.color: input.activeFocus ? Theme.accent : Theme.surface
    border.width: 1

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: Theme.padding
        anchors.rightMargin: Theme.padding
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.inverse
        font.family: Theme.font
        font.pixelSize: Theme.fontSize

        Keys.onEscapePressed: field.escaped()
        Keys.onTabPressed: field.next?.focusInput()
        onAccepted: {
            field.accepted(text);
            text = "";
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: field.placeholder
            color: Theme.muted
        }
    }
}
