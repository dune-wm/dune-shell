import QtQuick
import Quickshell

// The clock, and a click opens the month over it: today marked, the arrows or the wheel
// go to the months before and after, a click on the month comes back to today. A click
// away closes it. Names and the first day of the week follow the system's locale.
Widget {
    id: calendar

    // The calendar is open, so the corner has to stay.
    readonly property bool menuOpen: popup.visible
    readonly property var locale: Qt.locale()

    // The month shown: its year and month (0-11).
    property int year: 0
    property int month: 0

    text: Qt.formatDateTime(clock.date, "ddd d  HH:mm")
    tooltip: popup.visible ? "" : Qt.formatDateTime(clock.date, "dddd d MMMM yyyy")

    function today() {
        const now = new Date();
        year = now.getFullYear();
        month = now.getMonth();
    }

    function step(by) {
        const at = new Date(year, month + by, 1);
        year = at.getFullYear();
        month = at.getMonth();
    }

    onClicked: button => {
        if (button !== Qt.LeftButton)
            return;
        if (!popup.visible)
            today();
        popup.visible = !popup.visible;
    }
    onScrolled: up => {
        if (popup.visible)
            step(up ? -1 : 1);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    PopupWindow {
        id: popup

        // Over the clock, its right side on the pill's: it grows to the left, since the
        // clock is at the right edge of the monitor.
        anchor.item: calendar
        anchor.edges: Edges.Top | Edges.Right
        anchor.gravity: Edges.Top | Edges.Left
        anchor.margins.top: -Theme.padding - Theme.margin
        anchor.margins.right: -Theme.padding
        grabFocus: true
        color: "transparent"
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight

        Rectangle {
            id: card

            readonly property int cell: 34

            implicitWidth: 7 * cell + 2 * Theme.padding
            implicitHeight: content.implicitHeight + 2 * Theme.padding
            radius: Theme.radius
            color: Theme.background
            border.color: Theme.surface
            border.width: 1

            WheelHandler {
                onWheel: event => calendar.step(event.angleDelta.y > 0 ? -1 : 1)
            }

            Column {
                id: content
                x: Theme.padding
                y: Theme.padding
                spacing: Theme.margin

                // The month, between the arrows.
                Item {
                    width: 7 * card.cell
                    height: card.cell

                    Label {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: card.cell
                        horizontalAlignment: Text.AlignHCenter
                        text: "󰅁"
                        color: back.containsMouse ? Theme.accent : Theme.text

                        MouseArea {
                            id: back
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: calendar.step(-1)
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: {
                            const name = calendar.locale.standaloneMonthName(calendar.month);
                            return name.charAt(0).toUpperCase() + name.slice(1) + " " + calendar.year;
                        }
                        font.bold: true
                        color: home.containsMouse ? Theme.accent : Theme.text

                        MouseArea {
                            id: home
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: calendar.today()
                        }
                    }

                    Label {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: card.cell
                        horizontalAlignment: Text.AlignHCenter
                        text: "󰅂"
                        color: next.containsMouse ? Theme.accent : Theme.text

                        MouseArea {
                            id: next
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: calendar.step(1)
                        }
                    }
                }

                // The days of the week, from the locale's first one.
                Row {
                    Repeater {
                        model: 7

                        delegate: Label {
                            required property int index
                            width: card.cell
                            horizontalAlignment: Text.AlignHCenter
                            text: calendar.locale.dayName((calendar.locale.firstDayOfWeek + index) % 7, Locale.ShortFormat).slice(0, 2)
                            color: Theme.muted
                            font.pixelSize: Theme.fontSize - 2
                        }
                    }
                }

                // Six weeks, so the card keeps its size from month to month.
                Grid {
                    id: days
                    columns: 7

                    readonly property date first: {
                        const first = new Date(calendar.year, calendar.month, 1);
                        const offset = (first.getDay() - calendar.locale.firstDayOfWeek + 7) % 7;
                        return new Date(calendar.year, calendar.month, 1 - offset);
                    }

                    Repeater {
                        model: 42

                        delegate: Rectangle {
                            id: day

                            required property int index
                            readonly property date date: new Date(days.first.getFullYear(), days.first.getMonth(), days.first.getDate() + index)
                            readonly property bool inMonth: date.getMonth() === calendar.month
                            readonly property bool isToday: date.toDateString() === clock.date.toDateString()

                            width: card.cell
                            height: card.cell - 6
                            radius: Theme.radius / 2
                            color: isToday ? Theme.accent : "transparent"

                            Label {
                                anchors.centerIn: parent
                                text: day.date.getDate()
                                font.bold: day.isToday
                                color: day.isToday ? Theme.inverse : day.inMonth ? Theme.text : Theme.muted
                            }
                        }
                    }
                }
            }
        }
    }
}
