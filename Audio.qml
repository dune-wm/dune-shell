import QtQuick
import Quickshell.Services.Pipewire

// The default output's volume, with a mark when the microphone is muted: click mutes,
// scroll changes the volume by 5%.
Widget {
    id: audio

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool muted: sink?.audio?.muted ?? true
    readonly property int volume: Math.round(100 * (sink?.audio?.volume ?? 0))
    readonly property bool micMuted: source?.audio?.muted ?? false

    text: (muted ? "󰝟" : volume < 34 ? "󰕿" : volume < 67 ? "󰖀" : "󰕾")
        + (muted ? "" : " " + volume + "%") + (micMuted ? "  󰍭" : "")
    color: muted ? Theme.muted : Theme.text
    tooltip: (sink?.description ?? "No output") + (source ? "\nMicrophone: " + source.description : "")

    onClicked: button => {
        if (button === Qt.LeftButton && sink?.audio)
            sink.audio.muted = !sink.audio.muted;
        else if (button === Qt.RightButton && source?.audio)
            source.audio.muted = !source.audio.muted;
    }
    onScrolled: up => {
        if (sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (up ? 0.05 : -0.05)));
    }

    // Pipewire only fills in the nodes it is asked to track.
    PwObjectTracker {
        objects: [audio.sink, audio.source]
    }
}
