import QtQuick

// The rounded box every corner widget sits in.
Rectangle {
    default property alias content: row.data

    implicitWidth: row.implicitWidth + 2 * Theme.padding
    implicitHeight: row.implicitHeight + Theme.padding
    radius: Theme.radius
    color: Theme.background
    border.color: Theme.surface
    border.width: 1

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.padding
    }
}
