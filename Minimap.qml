import QtQuick
import Quickshell

// The strip of tiles a monitor shows, scaled down: every tile in its place with dune's
// thumbnail of it and its app, the focused one framed, and a frame around the part on
// screen. Its height is fixed and its width follows the strip, growing as tiles pile up
// until the monitor's width, past which everything shrinks to fit. Click a tile to go to
// it; the wheel goes to the tile before or after the focused one.
Rectangle {
    id: minimap

    required property string output
    // As wide as it gets (the monitor).
    property real maxWidth: 1920

    readonly property var strip: Dune.strips[output] ?? null
    readonly property var tiles: strip ? strip.tiles.slice().sort((a, b) => a.x - b.x || a.y - b.y) : []
    // The strip's length: its last tile, or the view when that goes further.
    readonly property real length: strip ? Math.max(strip.view + strip.width, ...tiles.map(t => t.x + t.w)) : 1
    // The strip fills the height, unless it would be wider than the monitor then.
    readonly property real factor: strip ? Math.min((Theme.minimapHeight - 2 * Theme.padding) / strip.height, (maxWidth - 2 * Theme.padding) / length) : 1
    // Centered when the strip is shorter than the minimap.
    readonly property real startX: (width - length * factor) / 2
    readonly property real startY: strip ? (height - strip.height * factor) / 2 : 0
    // Bumped to read the thumbnails again.
    property int stamp: 0

    implicitWidth: Math.min(maxWidth, Math.max(Theme.minimapMinWidth, (strip ? length * factor : 0) + 2 * Theme.padding))
    implicitHeight: Theme.minimapHeight
    radius: Theme.radius
    color: Theme.background
    border.color: Theme.surface
    border.width: 1

    // Enter or Escape while it has the keyboard.
    signal done()

    // What it shows, for dune-voice ("next", "first", a window's name): written to
    // $XDG_RUNTIME_DIR/dune-shell-minimap-OUTPUT.json while open, `{}` once closed.
    readonly property string statePath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + `/dune-shell-minimap-${output}.json`
    readonly property string shown: visible ? JSON.stringify({
        output: output,
        focused: Dune.focused,
        tiles: tiles.map(t => ({
            tile: t.tile,
            app: (Dune.windows[t.tile]?.app_id ?? "").split(".").pop(),
            title: Dune.windows[t.tile]?.title ?? ""
        }))
    }) : "{}"
    onShownChanged: Quickshell.execDetached(["sh", "-c", 'printf "%s" "$2" > "$1.tmp" && mv "$1.tmp" "$1"', "sh", statePath, shown])

    function pick(index) {
        if (tiles.length > 0)
            Dune.goTo(tiles[Math.max(0, Math.min(tiles.length - 1, index))].tile);
    }

    // Opened by its key it has the keyboard: the arrows move along the strip.
    focus: true
    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Left:
        case Qt.Key_Up:
            minimap.step(true);
            break;
        case Qt.Key_Right:
        case Qt.Key_Down:
            minimap.step(false);
            break;
        case Qt.Key_Home:
            minimap.pick(0);
            break;
        case Qt.Key_End:
            minimap.pick(minimap.tiles.length - 1);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Escape:
            minimap.done();
            break;
        default:
            return;
        }
        event.accepted = true;
    }

    function step(up) {
        if (tiles.length === 0)
            return;
        const at = tiles.findIndex(t => t.tile === Dune.focused);
        const next = at < 0 ? 0 : Math.max(0, Math.min(tiles.length - 1, at + (up ? -1 : 1)));
        Dune.goTo(tiles[next].tile);
    }

    // dune redraws them every few seconds while they change.
    Timer {
        interval: Theme.thumbnailRefresh
        running: minimap.visible && Dune.thumbnails !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: minimap.stamp++
    }

    Label {
        anchors.centerIn: parent
        visible: minimap.tiles.length === 0
        text: minimap.strip ? "No windows" : "dune does not tell its strip (update dune)"
        color: Theme.muted
    }

    Repeater {
        model: minimap.tiles

        delegate: Rectangle {
            id: tile

            required property var modelData
            readonly property var window: Dune.windows[modelData.tile] ?? null
            readonly property bool focused: modelData.tile === Dune.focused

            x: minimap.startX + modelData.x * minimap.factor
            y: minimap.startY + modelData.y * minimap.factor
            width: Math.max(2, modelData.w * minimap.factor)
            height: Math.max(2, modelData.h * minimap.factor)
            radius: 4
            color: Theme.surface
            clip: true

            Image {
                id: thumbnail
                anchors.fill: parent
                // Read at once from tmpfs: the old picture stays until the new one is in.
                asynchronous: false
                cache: false
                fillMode: Image.PreserveAspectCrop
                horizontalAlignment: Image.AlignLeft
                verticalAlignment: Image.AlignTop
                source: Dune.thumbnails && minimap.visible ? `file://${Dune.thumbnails}/${tile.modelData.tile}.png?${minimap.stamp}` : ""
            }

            // Its app on a band at the bottom; app and title when there is no picture
            // (a private window).
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: name.implicitHeight + 4
                color: tile.focused ? Theme.accent : Qt.rgba(0, 0, 0, 0.6)
                visible: thumbnail.status === Image.Ready

                Label {
                    id: name
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    verticalAlignment: Text.AlignVCenter
                    text: tile.window ? tile.window.app_id.split(".").pop() : ""
                    color: tile.focused ? Theme.inverse : Theme.text
                    font.pixelSize: Theme.fontSize - 2
                    font.bold: true
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 2
                visible: thumbnail.status !== Image.Ready

                Label {
                    width: parent.width
                    text: tile.window ? tile.window.app_id.split(".").pop() : ""
                    color: Theme.text
                    font.bold: true
                }
                Label {
                    width: parent.width
                    text: tile.window?.title ?? ""
                    color: Theme.muted
                    font.pixelSize: Theme.fontSize - 2
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                }
            }

            // Focused or under the cursor: framed.
            Rectangle {
                anchors.fill: parent
                color: mouse.containsMouse && !tile.focused ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                border.color: tile.focused ? Theme.accent : mouse.containsMouse ? Theme.text : "transparent"
                border.width: 2
                radius: 4
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Dune.goTo(tile.modelData.tile)
            }
        }
    }

    // The part of the strip on screen.
    Rectangle {
        visible: minimap.strip !== null
        x: minimap.startX + (minimap.strip?.view ?? 0) * minimap.factor - 2
        y: minimap.startY - 2
        width: (minimap.strip?.width ?? 0) * minimap.factor + 4
        height: (minimap.strip?.height ?? 0) * minimap.factor + 4
        color: "transparent"
        border.color: Theme.text
        border.width: 1
        radius: 3
    }

    WheelHandler {
        onWheel: event => minimap.step(event.angleDelta.y > 0)
    }
}
