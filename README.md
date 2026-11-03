# dune-shell

The widgets of [dune](../dune), made with [Quickshell](https://quickshell.org). They
take no space: each one is hidden in a corner of a monitor until the cursor rests on
the edge near it, and goes back once the cursor leaves.

- Bottom left: the dock of the monitor (`󱂩 3`, the entries it holds), then its desks.
- Bottom right: everything waybar showed: network, bluetooth, audio, the dictation
  language (`󰍬 EN`: a click opens English, Español, Italiano, the one picked marked
  while Hex switches; a right click English), media,
  notifications, clipboard, tray and the clock (a click opens the month). On the main
  monitor (`mainOutput`) the work and system status moves to the top right corner:
  recording, tasks, the daily log, VPN, CPU, memory, temperature and updates.
- Middle of the top edge (or the bottom one, `minimapEdges`): a minimap of the strip of
  tiles, to jump to any of them.

The tooltip of the widget under the cursor shows next to its pill. The desks come from
dune's ext-workspace, the minimap and the dock from `dune events`, dune's event stream.

## Dock

dune only publishes each monitor's dock (`dune events dock`) and does what is asked of
it (`dune dock take TILE`, `dune dock pin TILE [OUTPUT]`); the shell draws it. A click on
`󱂩` in the bottom left pill, or dune's `dock_show` key (Mod+Shift+e, `dune dock show`),
unfolds it upward from above the pill: the scratchpad nearest the pill, then the
entries, pinned ones (a dot) first. A column's cell has its number of tabs.

The chosen cell (under the cursor, or moved to with the keys) shows its title beside it;
a column with tabs, or the scratchpad with windows in it, fans them out there instead,
a row each.

- Click: take the entry out (a row of the fan: that tab, or that scratchpad window; the
  scratchpad cell: its first window). Right click: pin or unpin the entry.
- ↑/k ↓/j along the column (or the fan), →/l into the fan, ←/h out of it, Enter takes
  out, p or Space pins or unpins, Escape closes.

It closes on a pick, Escape, a click away from it or a window taking the focus. It takes
the keyboard only while it is shown. `dockCellSize`, `dockStagger` and `dockTitleWidth`
set its size, how staggered its unfold is and how wide its titles get.

## Tasks and log

**Tasks** (`󰄲 Work 3`) is [taskwarrior](https://taskwarrior.org) without a terminal.
Its tooltip has the most urgent tasks with when they are due (`!` when overdue). A
click opens them all, most urgent first:

- the circle of a task completes it;
- the field under them adds one, taskwarrior's modifiers kept
  (`pay rent due:friday +home project:house`);
- the modes at the top (a right click on the widget too) switch between the data dirs of
  `taskModes`, by default `personal` (`~/.task`) and `work` (`~/.task-work`). The mode
  is remembered in `~/.local/state/dune/task-mode`.

The list follows changes made elsewhere (a terminal, a sync) and is read again every
minute. taskwarrior runs with its hooks off.

**Log** (`󰠮 2`, today's entries) is a daily log of what you are on. Its tooltip has
today's last entries; a click opens them with a field to add one (Enter). The arrows,
the wheel or ←/→ go to the days before that have a log, a click on the date comes back
to today. Each day is a file `<logDir>/YYYY-MM-DD.log` (by default
`~/.local/share/dune/log`), a line per entry:

```
[10:56]  carga de horas sq1
```

In both popups Tab goes from field to field and Escape or a click away closes them.

## Run

```sh
ln -s ~/data-disk/my-projects/dune-shell ~/.config/quickshell/dune
qs -c dune
```

Quickshell reloads the files as they change.

## Settings

Colors, sizes, delays and monitors are read from `~/.config/dune/shell.json`
(`$XDG_CONFIG_HOME/dune/shell.json`), and read again when it changes. Every key is
optional: one left out keeps its default. `shell.example.json` has them all with their
defaults; `Theme.qml` says what each one does.

```sh
cp shell.example.json ~/.config/dune/shell.json
```

### The look of dune's tiles

A window, tiled like any other, sets the colors of the borders (the focused tile's and the
rest's, or none) and of the background, the border width, the gap and the corner radius;
the tab bars (their colors, height and title size); and the animations (on or off, how long
a resize slides and a close shrinks, and how small a closing tile ends).
Every change is written into dune's `dune.toml` with `dune config set` (comments kept) and
applied at once, so it shows on the tiles while it is chosen. Open or close it with

```sh
qs -c dune ipc call settings toggle   # e.g. [spawn] "mod+comma" = "..." in dune.toml
```

The keys of the minimap (`minimap`, Mod+a), the dock (`dock_show`) and the rest of dune's are in dune's own
`dune.toml`, `[keys]`. To start it with the session, add
`qs -c dune` to dune's autostart.

## Files

- `shell.qml`: the corners of each monitor.
- `Corner.qml`: a corner that opens on hover.
- `Dune.qml`: dune's state, from `dune events`.
- `Theme.qml`: colors, sizes and delays, from the settings file.
- `Widgets.qml`: the widgets of the right corners, in waybar's order, and the tooltip.
- `Widget.qml`, `ScriptWidget.qml`: text that runs commands on clicks; one that runs a
  waybar custom module script.
- `Dictation.qml`: Hex's dictation language, with its list of languages.
- `Calendar.qml`, `Tasks.qml`, `Log.qml`: the clock, taskwarrior and the daily log,
  each with a popup (`Field.qml` is the popups' text field).
- `NetworkWidget.qml`, `BluetoothWidget.qml`, `Audio.qml`, `Tray.qml`, `Stats.qml`:
  the system widgets and what they read.
- `Desks.qml`: the desks of a monitor.
- `Dock.qml`: the dock of a monitor, unfolding from the bottom left corner.
- `Minimap.qml`: the strip of tiles of a monitor, scaled down.
- `Settings.qml`: the window for the look of dune's tiles (`ColorPicker.qml`,
  `NumberSlider.qml` are its pieces).
- `Pill.qml`, `Label.qml`, `Separator.qml`: the pieces widgets are made of.
