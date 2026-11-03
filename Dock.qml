import QtQuick
import Quickshell
import Quickshell.Wayland

// The dock of a monitor, drawn from what dune publishes (Dune.docks): a column of cells
// unfolding upward from just above the bottom left pill, the scratchpad nearest the pill
// and dune's entries above it (pinned first). The chosen cell shows its title beside it,
// or the fan of its rows when it is a column with tabs (or the scratchpad with windows).
// A click takes an entry out, a right click pins or unpins it; the keys drive it while it
// is shown. dune keeps the data and does the actions, the dock only draws and asks.
//
// While shown it covers the whole monitor (transparent): the window never changes size
// under the cursor, and a click anywhere away from the cells closes it.
PanelWindow {
    id: dock

    readonly property string output: screen ? screen.name : ""
    readonly property var dockData: Dune.docks[output] ?? null
    readonly property var scratchpad: dockData?.scratchpad ?? []
    // From the pill up: the scratchpad, then dune's entries in its order. `rows` is what
    // the cell fans out beside it when chosen.
    readonly property var cells: [{ scratchpad: true, tile: scratchpad[0]?.tile ?? -1, app_id: "", title: "", pinned: false, rows: scratchpad }]
        .concat((dockData?.entries ?? []).map(e => ({ scratchpad: false, tile: e.tile, app_id: e.app_id ?? "", title: e.title ?? "", pinned: !!e.pinned, rows: e.tabs ?? [] })))
    readonly property int count: cells.length - 1

    // Mapped: unfolded, unfolding or folding back.
    property bool shown: false
    // Unfolded, or unfolding: false while it folds back before hiding.
    property bool unfolded: false
    // The chosen cell (0 the scratchpad) and the chosen row of its fan, -1 for none.
    property int chosen: 0
    property int fanIndex: -1
    // The tile of the chosen entry, to keep it chosen while dune reorders the dock (a pin).
    property int chosenTile: -1

    readonly property var chosenCell: cells[Math.min(chosen, cells.length - 1)]
    readonly property bool fanned: chosenCell.rows.length > 0

    readonly property int cellSize: Theme.dockCellSize
    readonly property int gap: Theme.margin
    // The bottom of the column: a margin above the pill, which sits a margin off the edge.
    readonly property real base: height - Theme.pillHeight - 2 * Theme.margin
    // How far a cell rises as it unfolds.
    readonly property real slideDistance: cellSize / 2
    // Between the starts of two cells unfolding: shorter when there are many, so the
    // whole unfold takes at most twice a corner's.
    readonly property int step: count > 0 ? Math.min(Theme.dockStagger, Math.round(2 * Theme.openDuration / count)) : 0

    // Every cell starts its own animation, staggered from the pill up (and back down).
    signal unfolding
    signal folding

    function cellY(index) {
        return base - (index + 1) * cellSize - index * gap;
    }

    function toggle() {
        if (unfolded)
            close();
        else
            open();
    }

    function open() {
        foldTimer.stop();
        if (!shown)
            choose(count > 0 ? 1 : 0);
        shown = true;
        unfolded = true;
        keys.forceActiveFocus();
        unfolding();
    }

    // Folds back, then hides.
    function close() {
        if (!unfolded)
            return;
        unfolded = false;
        folding();
        foldTimer.restart();
    }

    function choose(index) {
        chosen = Math.max(0, Math.min(cells.length - 1, index));
        chosenTile = cells[chosen].scratchpad ? -1 : cells[chosen].tile;
        fanIndex = -1;
    }

    // dune sent the dock again: the chosen entry stays chosen where it went, or the one
    // in its place when it left.
    onCellsChanged: {
        const at = chosenTile < 0 ? -1 : cells.findIndex(c => !c.scratchpad && c.tile === chosenTile);
        chosen = at >= 0 ? at : Math.min(chosen, cells.length - 1);
        chosenTile = cells[chosen].scratchpad ? -1 : cells[chosen].tile;
        fanIndex = Math.min(fanIndex, cells[chosen].rows.length - 1);
    }

    // Up and down along the column, or along the fan once in it.
    function move(up) {
        if (fanIndex >= 0)
            fanIndex = Math.max(0, Math.min(chosenCell.rows.length - 1, fanIndex + (up ? -1 : 1)));
        else
            choose(chosen + (up ? 1 : -1));
    }

    // Into the fan, on the tab shown (the entry's lead) or the first row.
    function enterFan() {
        if (!fanned || fanIndex >= 0)
            return;
        fanIndex = Math.max(0, chosenCell.rows.findIndex(r => r.tile === chosenCell.tile));
    }

    // Takes out the chosen row, else the chosen entry; the scratchpad gives its first.
    function take() {
        const tile = fanIndex >= 0 ? chosenCell.rows[fanIndex].tile : chosenCell.tile;
        if (tile < 0)
            return;
        Dune.takeFromDock(tile);
        close();
    }

    // Pins or unpins the chosen entry; the scratchpad has nothing to pin.
    function pin() {
        if (!chosenCell.scratchpad)
            Dune.pinInDock(chosenCell.tile, output);
    }

    // The app's icon from its desktop entry (or its id as an icon name), "" when there is
    // none. Reads the entries so it looks again once they are loaded.
    function iconFor(appId) {
        const loaded = DesktopEntries.applications.values;
        if (!appId)
            return "";
        const entry = DesktopEntries.heuristicLookup(appId);
        return Quickshell.iconPath(entry?.icon ?? appId, true);
    }

    function appName(appId) {
        return (appId ?? "").split(".").pop();
    }

    // A window taking the focus (a pick, a click on a window) is done with the dock.
    Connections {
        target: Dune
        function onFocusedChanged() {
            dock.close();
        }
    }

    Timer {
        id: foldTimer
        interval: Theme.closeDuration + dock.step * dock.count + 20
        onTriggered: dock.shown = false
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shown

    WlrLayershell.namespace: "dune-shell-dock"
    // Over the corners, so the click that closes it does not reach them.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: unfolded ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Folding back, the clicks already go through to what is under it.
    mask: unfolded ? null : nothing

    Region {
        id: nothing
    }

    // A click away from the cells.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: dock.close()
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Up:
            case Qt.Key_K:
                dock.move(true);
                break;
            case Qt.Key_Down:
            case Qt.Key_J:
                dock.move(false);
                break;
            case Qt.Key_Right:
            case Qt.Key_L:
                dock.enterFan();
                break;
            case Qt.Key_Left:
            case Qt.Key_H:
                dock.fanIndex = -1;
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                dock.take();
                break;
            case Qt.Key_P:
            case Qt.Key_Space:
                dock.pin();
                break;
            case Qt.Key_Escape:
                dock.close();
                break;
            default:
                return;
            }
            event.accepted = true;
        }
    }

    // An app's icon, or the first letter of its name when it has none.
    component AppIcon: Item {
        id: icon
        property string appId
        property color letterColor: Theme.text
        readonly property string path: dock.iconFor(appId)

        Image {
            anchors.fill: parent
            source: icon.path
            sourceSize.width: width
            sourceSize.height: height
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: icon.path !== ""
        }
        Label {
            anchors.centerIn: parent
            visible: icon.path === ""
            text: dock.appName(icon.appId).charAt(0).toUpperCase() || "?"
            color: icon.letterColor
            font.pixelSize: Math.round(icon.height * 0.7)
            font.bold: true
        }
    }

    Repeater {
        model: dock.cells

        delegate: Rectangle {
            id: cell

            required property var modelData
            required property int index
            readonly property bool chosen: index === dock.chosen
            // 0 folded into the pill, 1 in its place.
            property real progress: 0

            x: Theme.margin
            y: dock.cellY(index)
            width: dock.cellSize
            height: dock.cellSize
            radius: Theme.radius
            color: chosen || mouse.containsMouse ? Theme.surface : Theme.background
            border.color: chosen ? Theme.accent : Theme.surface
            border.width: chosen ? 2 : 1
            opacity: progress
            transform: Translate {
                y: (1 - cell.progress) * dock.slideDistance
            }

            Component.onCompleted: progress = dock.unfolded ? 1 : 0

            Connections {
                target: dock
                // Back from where it is: one already on its way does not wait its turn.
                function onUnfolding() {
                    fold.stop();
                    unfoldPause.duration = cell.progress > 0 ? 0 : cell.index * dock.step;
                    unfold.restart();
                }
                function onFolding() {
                    unfold.stop();
                    foldPause.duration = (dock.count - cell.index) * dock.step;
                    fold.restart();
                }
            }

            SequentialAnimation {
                id: unfold
                PauseAnimation {
                    id: unfoldPause
                }
                NumberAnimation {
                    target: cell
                    property: "progress"
                    to: 1
                    duration: Theme.openDuration
                    easing.type: Easing.OutCubic
                }
            }

            SequentialAnimation {
                id: fold
                PauseAnimation {
                    id: foldPause
                }
                NumberAnimation {
                    target: cell
                    property: "progress"
                    to: 0
                    duration: Theme.closeDuration
                    easing.type: Easing.InCubic
                }
            }

            AppIcon {
                anchors.fill: parent
                anchors.margins: Theme.padding
                appId: cell.modelData.app_id
                visible: !cell.modelData.scratchpad
            }

            // The scratchpad: a tray, muted while nothing waits in it.
            Label {
                anchors.centerIn: parent
                visible: cell.modelData.scratchpad
                text: ""
                color: cell.modelData.rows.length > 0 ? Theme.text : Theme.muted
                font.pixelSize: Math.round(dock.cellSize * 0.45)
            }

            // Pinned: a dot in its top left corner.
            Rectangle {
                visible: cell.modelData.pinned
                x: 4
                y: 4
                width: 6
                height: 6
                radius: 3
                color: Theme.accent
            }

            // How many tabs the column has (windows in the scratchpad).
            Rectangle {
                visible: cell.modelData.rows.length > (cell.modelData.scratchpad ? 0 : 1)
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 2
                width: Math.max(height, badge.implicitWidth + 6)
                height: badge.implicitHeight + 2
                radius: height / 2
                color: Theme.accent

                Label {
                    id: badge
                    anchors.centerIn: parent
                    text: cell.modelData.rows.length
                    color: Theme.inverse
                    font.pixelSize: Theme.fontSize - 3
                    font.bold: true
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    if (!cell.chosen)
                        dock.choose(cell.index);
                }
                onClicked: event => {
                    dock.choose(cell.index);
                    if (event.button === Qt.RightButton)
                        dock.pin();
                    else
                        dock.take();
                }
            }
        }
    }

    // Beside the chosen cell: its title, when it fans nothing out.
    Rectangle {
        id: title

        readonly property string text: dock.chosenCell.scratchpad ? "Scratchpad (empty)"
            : (dock.chosenCell.title || dock.appName(dock.chosenCell.app_id))

        x: 2 * Theme.margin + dock.cellSize
        y: dock.cellY(dock.chosen) + (dock.cellSize - height) / 2
        width: Math.min(Theme.dockTitleWidth, titleLabel.implicitWidth + 2 * Theme.padding)
        height: titleLabel.implicitHeight + Theme.padding
        radius: Theme.radius
        color: Theme.background
        border.color: Theme.surface
        border.width: 1
        visible: opacity > 0 && !dock.fanned
        opacity: dock.unfolded ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: dock.unfolded ? Theme.openDuration : Theme.closeDuration
            }
        }

        Label {
            id: titleLabel
            anchors.fill: parent
            anchors.leftMargin: Theme.padding
            anchors.rightMargin: Theme.padding
            verticalAlignment: Text.AlignVCenter
            text: title.text
        }
    }

    // Beside the chosen cell: the tabs of its column (the windows of the scratchpad), a
    // row each, rising from the cell's bottom.
    Rectangle {
        id: fan

        readonly property int rowHeight: Theme.fontSize + 16

        x: 2 * Theme.margin + dock.cellSize
        y: Math.max(Theme.margin, dock.cellY(dock.chosen) + dock.cellSize - height)
        width: Theme.dockTitleWidth
        height: rows.implicitHeight + 2 * Theme.margin
        radius: Theme.radius
        color: Theme.background
        border.color: Theme.surface
        border.width: 1
        visible: opacity > 0 && dock.fanned
        opacity: dock.unfolded ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: dock.unfolded ? Theme.openDuration : Theme.closeDuration
            }
        }

        Column {
            id: rows
            x: Theme.margin
            y: Theme.margin
            width: parent.width - 2 * Theme.margin

            Repeater {
                model: dock.fanned ? dock.chosenCell.rows : []

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property bool chosen: index === dock.fanIndex
                    // The tab the column shows.
                    readonly property bool lead: !dock.chosenCell.scratchpad && modelData.tile === dock.chosenCell.tile

                    width: rows.width
                    height: fan.rowHeight
                    radius: Theme.radius / 2
                    color: chosen ? Theme.accent : rowMouse.containsMouse ? Theme.surface : "transparent"

                    AppIcon {
                        id: rowIcon
                        x: Theme.margin
                        anchors.verticalCenter: parent.verticalCenter
                        width: fan.rowHeight - 8
                        height: width
                        appId: row.modelData.app_id ?? ""
                        letterColor: row.chosen ? Theme.inverse : Theme.text
                    }

                    Label {
                        anchors.left: rowIcon.right
                        anchors.leftMargin: Theme.margin
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.margin
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.title || dock.appName(row.modelData.app_id)
                        color: row.chosen ? Theme.inverse : row.lead ? Theme.accent : Theme.text
                        font.bold: row.lead
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onEntered: dock.fanIndex = row.index
                        onClicked: event => {
                            dock.fanIndex = row.index;
                            if (event.button === Qt.RightButton)
                                dock.pin();
                            else
                                dock.take();
                        }
                    }
                }
            }
        }
    }
}
