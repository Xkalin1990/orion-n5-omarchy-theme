#!/usr/bin/env bash
# Orion N5 // D350 Orbital Data System — Full-Set Installer for Omarchy Linux
# Installs the complete theme suite with 100% theme-aware auto-sync hooks so
# switching to any other Omarchy theme cleanly restores your previous setup.
#
# Usage:
#   ./install.sh              # Install full user-space theme suite & apply
#   ./install.sh --with-boot  # Also install Plymouth bootsplash & SDDM login (requires sudo)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WITH_BOOT=false
[[ "${1:-}" == "--with-boot" ]] && WITH_BOOT=true

echo "==> [1/7] Linking Orion N5 theme into ~/.config/omarchy/themes/orion-n5 ..."
mkdir -p "${HOME}/.config/omarchy/themes"
ln -sfn "${REPO_DIR}" "${HOME}/.config/omarchy/themes/orion-n5"

echo "==> [2/7] Installing Orion-N5 SVG icon pack, reticle cursor, & Liga SFMono Nerd Font ..."
mkdir -p "${HOME}/.local/share/icons" "${HOME}/.local/share/fonts"
cp -a "${REPO_DIR}/assets/icons/Orion-N5" "${HOME}/.local/share/icons/"
cp -a "${REPO_DIR}/assets/icons/Orion-N5-Cursor" "${HOME}/.local/share/icons/"
if ! fc-list : family 2>/dev/null | grep -qi "Liga SFMono Nerd Font"; then
  git clone --depth 1 https://github.com/shaunsingh/SFMono-Nerd-Font-Ligaturized.git /tmp/sfmono-orion-n5 2>/dev/null && {
    mkdir -p "${HOME}/.local/share/fonts/SFMono-Nerd-Font-Ligaturized"
    cp /tmp/sfmono-orion-n5/*.otf /tmp/sfmono-orion-n5/*.ttf "${HOME}/.local/share/fonts/SFMono-Nerd-Font-Ligaturized/" 2>/dev/null || true
    rm -rf /tmp/sfmono-orion-n5
    fc-cache -f >/dev/null 2>&1 || true
  } || true
fi

echo "==> [3/7] Installing Quickshell orion.telemetry & orion.deck plugins & bar logo ..."
mkdir -p "${HOME}/.config/omarchy/plugins"
rm -rf "${HOME}/.config/omarchy/plugins/orion.telemetry" "${HOME}/.config/omarchy/plugins/orion.deck"
cp -a "${REPO_DIR}/assets/orion.telemetry" "${HOME}/.config/omarchy/plugins/"
cp -a "${REPO_DIR}/assets/orion.deck" "${HOME}/.config/omarchy/plugins/"
if [[ -d "${HOME}/.config/omarchy/plugins/omarchy.menu" ]]; then
  cp "${REPO_DIR}/assets/orion-n5-bar-logo.svg" "${HOME}/.config/omarchy/plugins/omarchy.menu/orion-n5-logo.svg"
fi

echo "==> [4/7] Installing theme-aware Bash banner & tmux hook ..."
cp "${REPO_DIR}/assets/orion-n5-banner.sh" "${HOME}/.config/omarchy/orion-n5-banner.sh"
if [[ -f "${HOME}/.bashrc" ]] && ! grep -q "orion-n5-banner.sh" "${HOME}/.bashrc"; then
  cat >> "${HOME}/.bashrc" <<'BASHRC'

# Orion N5 theme-aware terminal header
if [[ -t 1 && -f "$HOME/.config/omarchy/orion-n5-banner.sh" ]]; then
  if [[ "$(tr '[:upper:]' '[:lower:]' < "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null)" == "orion-n5" ]]; then
    source "$HOME/.config/omarchy/orion-n5-banner.sh"
  fi
fi
BASHRC
fi

if [[ -f "${HOME}/.config/tmux/tmux.conf" ]]; then
  sed -i '/tmux-orion-n5\.conf/d' "${HOME}/.config/tmux/tmux.conf"
  printf '\n# Orion N5 telemetry status bar (theme-aware)\nif-shell '\''[ "$(cat ~/.local/state/omarchy/current/theme.name 2>/dev/null)" = "orion-n5" ] && [ -f ~/.config/omarchy/themes/orion-n5/assets/tmux-orion-n5.conf ]'\'' '\''source-file ~/.config/omarchy/themes/orion-n5/assets/tmux-orion-n5.conf'\''\n' >> "${HOME}/.config/tmux/tmux.conf"
fi

echo "==> [5/7] Installing Orion N5 low-intensity CRT shader ..."
if [[ -f "${REPO_DIR}/assets/crt-scanlines-orion-n5.glsl" ]]; then
  mkdir -p "${HOME}/.config/hypr/shaders"
  cp "${REPO_DIR}/assets/crt-scanlines-orion-n5.glsl" "${HOME}/.config/hypr/shaders/crt-scanlines-orion-n5.glsl"
fi

echo "==> [6/7] Installing reversible theme-set.d auto-sync hook & Orion Deck widget pack ..."
mkdir -p "${HOME}/.config/omarchy/hooks/theme-set.d"
cp "${REPO_DIR}/assets/orion-n5-sync.sh" "${HOME}/.config/omarchy/hooks/theme-set.d/orion-n5-sync.sh"
chmod +x "${HOME}/.config/omarchy/hooks/theme-set.d/orion-n5-sync.sh"
if command -v qmake6 >/dev/null 2>&1 && [[ -x "${REPO_DIR}/assets/deck/bin/install" ]]; then
  (cd "${REPO_DIR}/assets/deck" && ./bin/install --noconfirm) >/dev/null 2>&1 || true
fi

if [[ "${WITH_BOOT}" == true ]]; then
  echo "==> [7/7] Installing Plymouth bootsplash, SDDM login theme, owe, libvips, and ffmpegthumbnailer ..."
  sudo pacman -S --noconfirm --needed owe libvips ffmpegthumbnailer plymouth
  systemctl --user enable --now owed.service || true
  sudo "${REPO_DIR}/install-boot-login.sh"
else
  echo "==> [7/7] Skipping system-wide Plymouth/SDDM install (run './install.sh --with-boot' to include them)."
fi

echo "==> Applying Orion N5 theme ..."
omarchy theme set orion-n5
echo "==> Orion N5 installation complete! Switching to any other theme will cleanly restore your prior configs."
