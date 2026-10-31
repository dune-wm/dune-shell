import QtQuick
import Quickshell.Bluetooth

// Bluetooth on or off and what is connected; click opens bluetoothctl, right click
// turns it on or off.
Widget {
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var connected: {
        const devices = Bluetooth.devices.values ?? [];
        return devices.filter(d => d.connected).map(d => d.name);
    }

    visible: adapter !== null
    text: enabled ? "󰂯" + (connected.length > 0 ? " " + connected.length : "") : "󰂲"
    color: enabled ? Theme.text : Theme.muted
    tooltip: !enabled ? "Bluetooth off" : connected.length > 0 ? connected.join("\n") : "Bluetooth on"
    leftClick: "foot --app-id=waybar-float -e bluetoothctl"

    onClicked: button => {
        if (button === Qt.RightButton && adapter)
            adapter.enabled = !adapter.enabled;
    }
}
