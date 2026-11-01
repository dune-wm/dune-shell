import QtQuick

// A thin line between groups of widgets in a pill.
Rectangle {
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    implicitWidth: 1
    implicitHeight: Theme.fontSize + 6
    color: Theme.surface
}
