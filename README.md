# dune-shell

The widgets of [dune](../dune), made with [Quickshell](https://quickshell.org). They
take no space: each monitor has a widget in its two bottom corners, hidden until the
cursor rests on the bottom edge near that corner.

- Bottom left: the desk the monitor shows and the focused window.
- Bottom right: the date and time.

What they show comes from `dune events`, dune's event stream.

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

The keys of the minimap (`minimap`, Mod+a) and the rest of dune's are in dune's own
`dune.toml`, `[keys]`. To start it with the session, add
`qs -c dune` to dune's autostart.

## Files

- `shell.qml`: the corners of each monitor.
- `Corner.qml`: a corner that opens on hover.
- `Dune.qml`: dune's state, from `dune events`.
- `Theme.qml`: colors, sizes and delays, from the settings file.
- `Widgets.qml`, `Calendar.qml`, `Separator.qml`: the widgets of the right corners.
- `Minimap.qml`: the strip of tiles of a monitor, scaled down.
- `Pill.qml`, `Label.qml`: the pieces widgets are made of.
