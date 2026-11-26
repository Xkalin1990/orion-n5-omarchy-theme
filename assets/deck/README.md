# deck (Orion Deck)

A unified, theme-styled desktop telemetry widget pack for Omarchy. Launches from a single icon as a frameless top control bar with toggles for 6 independent, draggable desktop widget cards:

- **`EPOCH`** — Live clock, seconds, ISO week, and localized date
- **`TMINUS`** — Mission countdown / Pomodoro timer & stopwatch with chime
- **`UPLINK`** — Live connection / service beacon with latency sparkline
- **`SIGNAL`** — Minimal MPRIS (`playerctl`) Now Playing & media transport strip
- **`SLATE`** — Auto-saving floating markdown scratchpad (`~/.local/share/slate/note.md`)
- **`ZULU`** — Multi-zone mission clock (`ZULU`, `LON`, `NYC`, `TYO`)

## Shortcuts (Top Bar)

| Key | Action |
| --- | --- |
| `1` – `6` | Toggle widget card (`EPOCH`..`ZULU`) |
| `A` | Toggle all cards on/off |
| `?` | Toggle shortcuts overlay |
| `Ctrl+Q` | Quit Orion Deck |
| Drag | Move bar or any widget card |

## Build & Install

```sh
./bin/build
./bin/test
./bin/install
```
