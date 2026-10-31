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

Quickshell reloads the files as they change. To start it with the session, add
`qs -c dune` to dune's autostart.

## Files

- `shell.qml`: the corners of each monitor.
- `Corner.qml`: a corner that opens on hover.
- `Dune.qml`: dune's state, from `dune events`.
- `Theme.qml`: colors, sizes and delays.
- `Pill.qml`, `Label.qml`: the pieces widgets are made of.
