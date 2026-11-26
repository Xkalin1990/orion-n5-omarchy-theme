# slate

A frameless, draggable instant telemetry scratchpad widget for Omarchy. Notes are saved atomically to `~/.local/share/slate/note.md` with debounced auto-save, following the active Omarchy theme colors, Hyprland corner rounding, and system language live.

## Shortcuts

| Key | Action |
| --- | --- |
| `Ctrl+S` | Save now |
| `Ctrl+L` | Clear note |
| `?` | Toggle shortcuts |
| `Ctrl+Q` / `Esc` | Quit (or close help) |
| Drag header | Move widget on desktop |

## Build & Install

```sh
./bin/build
./bin/test
./bin/install
```
