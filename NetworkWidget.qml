import QtQuick
import Quickshell.Networking

// Whether a cable or wifi is connected; click opens nmtui.
Widget {
    readonly property var device: {
        const devices = Networking.devices.values ?? Networking.devices;
        for (let i = 0; i < devices.length; i++)
            if (devices[i].connected)
                return devices[i];
        return null;
    }

    text: device === null ? "󰖪" : device.type === DeviceType.Wifi ? "󰤨" : "󰈀"
    color: device === null ? Theme.muted : Theme.text
    tooltip: device === null ? "Disconnected" : device.name + (device.address ? ": " + device.address : "")
    leftClick: "foot --app-id=waybar-float -e nmtui"
}
