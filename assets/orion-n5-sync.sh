#!/usr/bin/env bash
# Orion N5 theme-set hook — keeps Fastfetch, Starship, Screensaver, Bar logo, and Foot PTYs in sync.
set -uo pipefail

THEME_SLUG="${1:-}"
THEME_DIR="${HOME}/.config/omarchy/themes/orion-n5"
MENU_QML="${HOME}/.config/omarchy/plugins/omarchy.menu/BarWidget.qml"

if [[ "${THEME_SLUG,,}" == "orion-n5" ]]; then
  [[ -f "${THEME_DIR}/assets/fastfetch-orion-n5.jsonc" ]] && {
    mkdir -p "${HOME}/.config/fastfetch"
    cp "${THEME_DIR}/assets/fastfetch-orion-n5.jsonc" "${HOME}/.config/fastfetch/config.jsonc"
  }
  [[ -f "${THEME_DIR}/assets/starship-orion-n5.toml" ]] && \
    cp "${THEME_DIR}/assets/starship-orion-n5.toml" "${HOME}/.config/starship.toml"
  [[ -f "${THEME_DIR}/assets/screensaver-orion-n5.txt" ]] && \
    cp "${THEME_DIR}/assets/screensaver-orion-n5.txt" "${HOME}/.config/omarchy/branding/screensaver.txt"

  if [[ -f "${MENU_QML}" ]]; then
    sed -i 's/wy-logo\.svg/orion-n5-logo.svg/g; s/width: 24/width: 18/g; s/height: 11/height: 18/g' "${MENU_QML}"
  fi

  # Also retint foot PTYs whose child redirected fd/1 (e.g. agy keeping pts on fd/0)
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
else
  [[ -f "${HOME}/.config/starship.toml.pre-orion-n5" ]] && \
    cp "${HOME}/.config/starship.toml.pre-orion-n5" "${HOME}/.config/starship.toml"
  [[ -f "${HOME}/.config/omarchy/branding/screensaver.txt.pre-orion-n5" ]] && \
    cp "${HOME}/.config/omarchy/branding/screensaver.txt.pre-orion-n5" "${HOME}/.config/omarchy/branding/screensaver.txt"
  rm -f "${HOME}/.config/fastfetch/config.jsonc"

  if [[ "${THEME_SLUG,,}" == "hyperdyne" && -f "${MENU_QML}" ]]; then
    sed -i 's/orion-n5-logo\.svg/wy-logo.svg/g; s/width: 18/width: 24/g; s/height: 18/height: 11/g' "${MENU_QML}"
  fi
fi
