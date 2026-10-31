pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory and temperature, read every few seconds from /proc and the k10temp sensor.
Singleton {
    id: stats

    property int cpu: 0
    property int memory: 0
    property int temperature: 0

    property var lastCpu: null

    readonly property string sensor: "/sys/bus/pci/drivers/k10temp/0000:00:18.3/hwmon/hwmon*/temp1_input"

    function read(text) {
        const lines = text.split("\n");
        // cpu  user nice system idle iowait irq softirq steal ...
        const ticks = lines[0].trim().split(/\s+/).slice(1).map(Number);
        const idle = ticks[3] + ticks[4];
        const total = ticks.reduce((a, b) => a + b, 0);
        if (lastCpu !== null && total > lastCpu.total)
            cpu = Math.round(100 * (1 - (idle - lastCpu.idle) / (total - lastCpu.total)));
        lastCpu = { idle, total };

        const kib = name => Number((lines.find(l => l.startsWith(name)) ?? "0 0").split(/\s+/)[1]);
        const total_mem = kib("MemTotal:");
        if (total_mem > 0)
            memory = Math.round(100 * (1 - kib("MemAvailable:") / total_mem));

        const last = Number(lines.filter(l => l.trim() !== "").pop());
        if (!isNaN(last))
            temperature = Math.round(last / 1000);
    }

    Process {
        id: process
        command: ["sh", "-c", `head -1 /proc/stat; grep -E '^Mem(Total|Available):' /proc/meminfo; cat ${stats.sensor} 2>/dev/null`]
        running: true
        stdout: StdioCollector {
            onStreamFinished: stats.read(text)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: process.running = true
    }
}
