# zulu

A frameless, draggable multi-zone mission clock strip widget for Omarchy. Follows the active Omarchy theme colors, Hyprland corner rounding, and system language live, and displays UTC (`ZULU`) alongside three pinned time zones (`LON`, `NYC`, `TYO` by default).

## Custom Zones

Optionally create `~/.config/zulu/zones.json` to configure the pinned zones:

```json
[
  { "zone": "Europe/London", "code": "LON", "city": "London" },
  { "zone": "America/New_York", "code": "NYC", "city": "New York" },
  { "zone": "Asia/Tokyo", "code": "TYO", "city": "Tokyo" }
]
```

## Shortcuts

| Key | Action |
| --- | --- |
| `Space` | Toggle 12h / 24h |
| `S` | Toggle seconds |
| `?` | Toggle shortcuts |
| `Q` / `Esc` | Quit / close help |
| Drag | Move widget on desktop |

## Build & Install

```sh
./bin/build
./bin/test
./bin/install
```
