# Orion N5 — Omarchy Theme

Industrial aerospace telemetry theme for [Omarchy](https://omarchy.org/), inspired by the **Orion N5 / D350 Orbital Data System** aesthetic: matte carbon slate (`#141615`), oxidized sage-mint (`#c4ddd0` / `#9ecab3`), and aerospace safety orange (`#ff5a1f`).

## Included Assets

- `colors.toml` — Master palette driving terminals (Alacritty, Ghostty, Kitty, Foot), `btop`, Helix, Chromium, Obsidian, VS Code, and Hyprland borders.
- `shell.toml` — Omarchy Shell (Quickshell) bar, notifications, launcher, polkit, and lock screen styling.
- `neovim.lua` — LazyVim / `aether.nvim` v3 configuration.
- `assets/` — Vector SVG emblems, telemetry glyphs, About badge, and 4K wallpaper sources.
- `backgrounds/` — Rendered 4K PNG wallpapers (`orion-n5-dark.png`, `orion-n5-telemetry.png`).

## Installation

```bash
ln -sfn ~/Work/orion-n5-theme ~/.config/omarchy/themes/orion-n5
omarchy theme set orion-n5
```

To apply the custom **About** window emblem:

```bash
omarchy-transcode-ascii ~/.config/omarchy/themes/orion-n5/assets/orion-n5-about-badge.svg ~/.config/omarchy/branding/about.txt --width 54 --height 26
```
