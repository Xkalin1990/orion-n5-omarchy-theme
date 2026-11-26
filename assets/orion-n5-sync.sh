#!/usr/bin/env bash
# Orion N5 theme-set hook — 100% theme-aware & reversible.
# Activates all Orion N5 features when switching to `orion-n5`,
# and cleanly restores previous configs when switching to any other theme.
set -uo pipefail

THEME_SLUG="${1:-}"
THEME_DIR="${HOME}/.config/omarchy/themes/orion-n5"
STATE_DIR="${HOME}/.local/state/omarchy/orion-n5-backup"
MENU_QML="${HOME}/.config/omarchy/plugins/omarchy.menu/BarWidget.qml"
SHELL_JSON="${HOME}/.config/omarchy/shell.json"

mkdir -p "${STATE_DIR}"

backup_once() {
  local src="$1"
  local name="$2"
  if [[ -f "${src}" && ! -f "${STATE_DIR}/${name}" ]]; then
    cp -a "${src}" "${STATE_DIR}/${name}"
  fi
}

restore_backup() {
  local dst="$1"
  local name="$2"
  if [[ -f "${STATE_DIR}/${name}" ]]; then
    cp -a "${STATE_DIR}/${name}" "${dst}"
  fi
}

if [[ "${THEME_SLUG,,}" == "orion-n5" ]]; then
  # 1. Fastfetch / About Window
  if [[ -f "${THEME_DIR}/assets/fastfetch-orion-n5.jsonc" ]]; then
    mkdir -p "${HOME}/.config/fastfetch"
    if [[ -f "${HOME}/.config/fastfetch/config.jsonc" ]] && ! grep -q "orion-n5-about-card" "${HOME}/.config/fastfetch/config.jsonc" 2>/dev/null; then
      backup_once "${HOME}/.config/fastfetch/config.jsonc" "fastfetch-config.jsonc"
    fi
    cp "${THEME_DIR}/assets/fastfetch-orion-n5.jsonc" "${HOME}/.config/fastfetch/config.jsonc"
  fi

  # 2. Starship prompt
  if [[ -f "${THEME_DIR}/assets/starship-orion-n5.toml" ]]; then
    if [[ -f "${HOME}/.config/starship.toml" ]] && ! grep -q "Orion N5" "${HOME}/.config/starship.toml" 2>/dev/null; then
      backup_once "${HOME}/.config/starship.toml" "starship.toml"
    fi
    cp "${THEME_DIR}/assets/starship-orion-n5.toml" "${HOME}/.config/starship.toml"
  fi

  # 3. Idle Screensaver
  if [[ -f "${THEME_DIR}/assets/screensaver-orion-n5.txt" ]]; then
    mkdir -p "${HOME}/.config/omarchy/branding"
    if [[ -f "${HOME}/.config/omarchy/branding/screensaver.txt" ]] && ! grep -q "ORBITAL DATA SYSTEM" "${HOME}/.config/omarchy/branding/screensaver.txt" 2>/dev/null; then
      backup_once "${HOME}/.config/omarchy/branding/screensaver.txt" "screensaver.txt"
    fi
    cp "${THEME_DIR}/assets/screensaver-orion-n5.txt" "${HOME}/.config/omarchy/branding/screensaver.txt"
  fi

  # 4. Lazygit
  if [[ -f "${THEME_DIR}/assets/lazygit-orion-n5.yml" ]]; then
    mkdir -p "${HOME}/.config/lazygit"
    if [[ -f "${HOME}/.config/lazygit/config.yml" ]] && ! grep -q "Orion N5" "${HOME}/.config/lazygit/config.yml" 2>/dev/null; then
      backup_once "${HOME}/.config/lazygit/config.yml" "lazygit-config.yml"
    fi
    cp "${THEME_DIR}/assets/lazygit-orion-n5.yml" "${HOME}/.config/lazygit/config.yml"
  fi

  # 5. btop telemetry tuning
  if [[ -f "${HOME}/.config/btop/btop.conf" ]]; then
    backup_once "${HOME}/.config/btop/btop.conf" "btop.conf"
    sed -i 's/^graph_symbol = .*/graph_symbol = "braille"/; s/^rounded_corners = .*/rounded_corners = False/' "${HOME}/.config/btop/btop.conf"
  fi

  # 6. Tmux live reload
  if [[ -f "${THEME_DIR}/assets/tmux-orion-n5.conf" ]]; then
    tmux source-file "${THEME_DIR}/assets/tmux-orion-n5.conf" 2>/dev/null || true
  fi

  # 7. Quickshell Bar: add orion.telemetry pill to centerBegin
  if [[ -f "${SHELL_JSON}" ]] && command -v jq >/dev/null 2>&1; then
    if ! jq -e '.bar.layout.centerBegin[]? | select(.id == "orion.telemetry")' "${SHELL_JSON}" >/dev/null 2>&1; then
      tmp=$(mktemp)
      if jq '.bar.layout.centerBegin = [{"id": "orion.telemetry"}] + (.bar.layout.centerBegin // [])' "${SHELL_JSON}" > "${tmp}"; then
        mv "${tmp}" "${SHELL_JSON}"
      else
        rm -f "${tmp}"
      fi
    fi
  fi

  # 8. Top-left Bar Menu Logo
  if [[ -f "${MENU_QML}" ]]; then
    if ! grep -q "orion-n5-logo.svg" "${MENU_QML}" 2>/dev/null; then
      backup_once "${MENU_QML}" "omarchy-menu-BarWidget.qml"
    fi
    sed -i 's/wy-logo\.svg/orion-n5-logo.svg/g; s/width: 24/width: 18/g; s/height: 11/height: 18/g' "${MENU_QML}"
  fi

  # 9. Technical Reticle Cursor
  if [[ -d "${HOME}/.local/share/icons/Orion-N5-Cursor" ]] && command -v hyprctl >/dev/null 2>&1; then
    hyprctl setcursor Orion-N5-Cursor 24 >/dev/null 2>&1 || true
  fi

  # 10. Retint running Foot PTYs whose child redirected fd/1 (e.g. agy on fd/0)
  COLORS_TOML="${HOME}/.local/state/omarchy/current/theme/colors.toml"
  if [[ -f "${COLORS_TOML}" ]] && command -v omarchy-theme-osc >/dev/null 2>&1; then
    OSC=$(omarchy-theme-osc "${COLORS_TOML}")
    OSC+=$(printf '\033]11;[100]#141615\007')
    for fpid in $(pgrep -x foot 2>/dev/null || true); do
      for cpid in $(pgrep -P "${fpid}" 2>/dev/null || true); do
        pts=$(readlink "/proc/${cpid}/fd/0" 2>/dev/null || true)
        [[ "${pts}" == /dev/pts/* ]] && printf '%b' "${OSC}" > "${pts}" 2>/dev/null || true
      done
    done
  fi

  # 11. Subtle telemetry activation chime
  SOUND="${THEME_DIR}/assets/sounds/telemetry-activate.wav"
  if [[ -f "${SOUND}" ]]; then
    (pw-play "${SOUND}" 2>/dev/null || paplay "${SOUND}" 2>/dev/null || true) &
  fi
else
  # Restore everything cleanly so zero Orion N5 artifacts remain on other themes
  if [[ -f "${STATE_DIR}/fastfetch-config.jsonc" ]]; then
    cp -a "${STATE_DIR}/fastfetch-config.jsonc" "${HOME}/.config/fastfetch/config.jsonc"
  else
    rm -f "${HOME}/.config/fastfetch/config.jsonc"
  fi

  restore_backup "${HOME}/.config/starship.toml" "starship.toml"
  restore_backup "${HOME}/.config/omarchy/branding/screensaver.txt" "screensaver.txt"
  restore_backup "${HOME}/.config/lazygit/config.yml" "lazygit-config.yml"
  restore_backup "${HOME}/.config/btop/btop.conf" "btop.conf"
  restore_backup "${MENU_QML}" "omarchy-menu-BarWidget.qml"

  # Remove orion.telemetry pill from Quickshell bar
  if [[ -f "${SHELL_JSON}" ]] && command -v jq >/dev/null 2>&1; then
    if jq -e '.bar.layout.centerBegin[]? | select(.id == "orion.telemetry")' "${SHELL_JSON}" >/dev/null 2>&1; then
      tmp=$(mktemp)
      if jq '.bar.layout.centerBegin = [(.bar.layout.centerBegin // [])[] | select(.id != "orion.telemetry")]' "${SHELL_JSON}" > "${tmp}"; then
        mv "${tmp}" "${SHELL_JSON}"
      else
        rm -f "${tmp}"
      fi
    fi
  fi

  # Reset cursor back to Adwaita
  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl setcursor Adwaita 24 >/dev/null 2>&1 || true
  fi

  # Reload tmux config so Orion N5 status bar clears in running tmux sessions
  if [[ -f "${HOME}/.config/tmux/tmux.conf" ]]; then
    tmux source-file "${HOME}/.config/tmux/tmux.conf" 2>/dev/null || true
  fi
fi
