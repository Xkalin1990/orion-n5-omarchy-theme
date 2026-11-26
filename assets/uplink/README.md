# uplink

A live, frameless connection and service status beacon widget for Omarchy. Follows the active Omarchy theme colors, Hyprland corner rounding, and system language live, and can be dragged anywhere on the desktop.

Monitors `1.1.1.1`, `github.com:443`, and `localhost:3000` by default (or custom targets from `~/.config/uplink/targets.json`) every 5 seconds.

## Shortcuts

| Key | Action |
| --- | --- |
| `Space` / `R` | Probe now |
| `T` | Cycle target |
| `?` | Toggle shortcuts |
| `Q` / `Esc` | Quit |
| Drag | Move widget on desktop |

## Build & Install

```sh
./bin/build
./bin/test
./bin/install
```
