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

  # 7. Quickshell Bar: add orion.telemetry & orion.deck pills to centerBegin, and local.oma-e to right + plugins[]
  if [[ -f "${SHELL_JSON}" ]] && command -v jq >/dev/null 2>&1; then
    if ! jq -e '.bar.layout.centerBegin[]? | select(.id == "orion.telemetry")' "${SHELL_JSON}" >/dev/null 2>&1; then
      tmp=$(mktemp)
      if jq '.bar.layout.centerBegin = [{"id": "orion.telemetry"}] + (.bar.layout.centerBegin // [])' "${SHELL_JSON}" > "${tmp}"; then
        mv "${tmp}" "${SHELL_JSON}"
      else
        rm -f "${tmp}"
      fi
    fi
    if ! jq -e '.bar.layout.centerBegin[]? | select(.id == "orion.deck")' "${SHELL_JSON}" >/dev/null 2>&1; then
      tmp=$(mktemp)
      if jq '.bar.layout.centerBegin = (.bar.layout.centerBegin // []) + [{"id": "orion.deck"}]' "${SHELL_JSON}" > "${tmp}"; then
        mv "${tmp}" "${SHELL_JSON}"
      else
        rm -f "${tmp}"
      fi
    fi
    if ! jq -e '.bar.layout.right[]? | select(.id == "local.oma-e")' "${SHELL_JSON}" >/dev/null 2>&1; then
      tmp=$(mktemp)
      if jq '
        .bar.layout.right = (
          (.bar.layout.right // []) as $r |
          (($r | map(.id) | index("omarchy.agents")) // -1) as $i |
          if $i >= 0 then $r[:$i+1] + [{"id": "local.oma-e"}] + $r[$i+1:]
          else [{"id": "local.oma-e"}] + $r end
        )
      ' "${SHELL_JSON}" > "${tmp}"; then
        mv "${tmp}" "${SHELL_JSON}"
      else
        rm -f "${tmp}"
      fi
    fi
    if ! jq -e '.plugins[]? | select(.id == "local.oma-e")' "${SHELL_JSON}" >/dev/null 2>&1; then
      tmp=$(mktemp)
      if jq '.plugins = (.plugins // []) + [{"id": "local.oma-e"}]' "${SHELL_JSON}" > "${tmp}"; then
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

  # 9. Technical Reticle Cursor (Hyprland + GTK)
  if [[ -d "${HOME}/.local/share/icons/Orion-N5-Cursor" ]]; then
    command -v hyprctl >/dev/null 2>&1 && {
      hyprctl setcursor Adwaita 24 >/dev/null 2>&1 || true
      hyprctl setcursor Orion-N5-Cursor 24 >/dev/null 2>&1 || true
    }
    command -v gsettings >/dev/null 2>&1 && \
      gsettings set org.gnome.desktop.interface cursor-theme 'Orion-N5-Cursor' >/dev/null 2>&1 || true
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

  # 11. Set Liga SFMono Nerd Font (backing up prior font once)
  if command -v omarchy-font-set >/dev/null 2>&1 && fc-list : family 2>/dev/null | grep -i "Liga SFMono Nerd Font" >/dev/null; then
    CURRENT_FONT=$(omarchy-font-current 2>/dev/null || true)
    if [[ -n "${CURRENT_FONT}" && "${CURRENT_FONT}" != "Liga SFMono Nerd Font" && ! -f "${STATE_DIR}/font.name" ]]; then
      printf '%s\n' "${CURRENT_FONT}" > "${STATE_DIR}/font.name"
    fi
    if [[ "${CURRENT_FONT}" != "Liga SFMono Nerd Font" ]]; then
      omarchy-font-set "Liga SFMono Nerd Font" >/dev/null 2>&1 || true
    fi
  fi

  # 12. Launch Orion Deck widget pack if installed
  if command -v deck >/dev/null 2>&1 && ! pgrep -x deck >/dev/null 2>&1; then
    setsid -f deck >/dev/null 2>&1 || true
  fi

  # 13. Subtle telemetry activation chime
  SOUND="${THEME_DIR}/assets/sounds/telemetry-activate.wav"
  if [[ -f "${SOUND}" ]]; then
    (pw-play "${SOUND}" 2>/dev/null || paplay "${SOUND}" 2>/dev/null || true) &
  fi
else
  # Restore everything cleanly so zero Orion N5 artifacts remain on other themes
  pkill -x deck >/dev/null 2>&1 || true
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

  # Remove orion.telemetry, orion.deck & local.oma-e from Quickshell bar and plugins[]
  if [[ -f "${SHELL_JSON}" ]] && command -v jq >/dev/null 2>&1; then
    if jq -e '(.bar.layout.centerBegin[]? | select(.id == "orion.telemetry" or .id == "orion.deck")), (.bar.layout.right[]? | select(.id == "local.oma-e")), (.plugins[]? | select(.id == "local.oma-e"))' "${SHELL_JSON}" >/dev/null 2>&1; then
      tmp=$(mktemp)
      if jq '
        .bar.layout.centerBegin = [(.bar.layout.centerBegin // [])[] | select(.id != "orion.telemetry" and .id != "orion.deck")] |
        .bar.layout.right = [(.bar.layout.right // [])[] | select(.id != "local.oma-e")] |
        .plugins = [(.plugins // [])[] | select(.id != "local.oma-e")]
      ' "${SHELL_JSON}" > "${tmp}"; then
        mv "${tmp}" "${SHELL_JSON}"
      else
        rm -f "${tmp}"
      fi
    fi
  fi

  # Reset cursor back to Adwaita (Hyprland + GTK)
  command -v hyprctl >/dev/null 2>&1 && \
    hyprctl setcursor Adwaita 24 >/dev/null 2>&1 || true
  command -v gsettings >/dev/null 2>&1 && \
    gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita' >/dev/null 2>&1 || true

  # Restore prior font
  if [[ -f "${STATE_DIR}/font.name" ]] && command -v omarchy-font-set >/dev/null 2>&1; then
    PREV_FONT=$(<"${STATE_DIR}/font.name")
    CURRENT_FONT=$(omarchy-font-current 2>/dev/null || true)
    if [[ -n "${PREV_FONT}" && "${CURRENT_FONT}" != "${PREV_FONT}" ]]; then
      omarchy-font-set "${PREV_FONT}" >/dev/null 2>&1 || true
    fi
  fi

  # Reload tmux config so Orion N5 status bar clears in running tmux sessions
  if [[ -f "${HOME}/.config/tmux/tmux.conf" ]]; then
    tmux source-file "${HOME}/.config/tmux/tmux.conf" 2>/dev/null || true
  fi
fi

# ── Screen-resolution wallpaper fitting (Orion N5 & Arasaka Corp) ───────────
fit_wallpaper_to_screen() {
  local slug="${THEME_SLUG,,}"
  [[ "${slug}" == "orion-n5" || "${slug}" == "arasaka-corp" ]] || return 0
  command -v ffmpeg >/dev/null 2>&1 || return 0
  command -v ffprobe >/dev/null 2>&1 || return 0
  command -v hyprctl >/dev/null 2>&1 || return 0
  command -v jq >/dev/null 2>&1 || return 0

  local bg_link="${HOME}/.local/state/omarchy/current/background"
  local bg_src
  bg_src="$(readlink -f "${bg_link}" 2>/dev/null || true)"
  [[ -f "${bg_src}" ]] || return 0

  local mon_dims mon_w mon_h
  mon_dims="$(hyprctl monitors -j 2>/dev/null | jq -r '.[0] | "\(.width) \(.height)"' 2>/dev/null || true)"
  read -r mon_w mon_h <<<"${mon_dims}"
  [[ "${mon_w:-0}" -gt 0 && "${mon_h:-0}" -gt 0 ]] || return 0

  local media_dims media_w="" media_h=""
  media_dims="$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "${bg_src}" 2>/dev/null | head -n1 || true)"
  IFS=',' read -r media_w media_h <<<"${media_dims}"
  [[ "${media_w:-0}" -gt 0 && "${media_h:-0}" -gt 0 ]] || return 0

  # Skip if aspect ratios already match within ~3% (e.g. 16:9 on 16:9)
  local needs_fit
  needs_fit="$(awk -v mw="${mon_w}" -v mh="${mon_h}" -v iw="${media_w}" -v ih="${media_h}" 'BEGIN {
    mr = mw / mh; ir = iw / ih;
    diff = (mr > ir) ? (mr - ir) / mr : (ir - mr) / ir;
    print (diff > 0.03) ? 1 : 0
  }')"
  [[ "${needs_fit}" == "1" ]] || return 0

  local pad_color="0x141615"
  [[ "${slug}" == "arasaka-corp" ]] && pad_color="0x0a0a0e"

  local cache_dir="${HOME}/.local/state/omarchy/fitted-backgrounds/${slug}/${mon_w}x${mon_h}"
  mkdir -p "${cache_dir}"
  local out_file="${cache_dir}/$(basename "${bg_src}")"

  if [[ ! -f "${out_file}" || "${bg_src}" -nt "${out_file}" ]]; then
    local vf="scale=${mon_w}:${mon_h}:force_original_aspect_ratio=decrease:flags=lanczos,pad=${mon_w}:${mon_h}:(ow-iw)/2:(oh-ih)/2:color=${pad_color}"
    if [[ "${bg_src,,}" =~ \.(mp4|m4v|mov|webm|mkv|avi)$ ]]; then
      ffmpeg -y -i "${bg_src}" -vf "${vf}" -c:v libx264 -preset fast -crf 18 -an -movflags +faststart "${out_file}" >/dev/null 2>&1 || return 0
    else
      ffmpeg -y -i "${bg_src}" -vf "${vf}" -frames:v 1 "${out_file}" >/dev/null 2>&1 || return 0
    fi
  fi

  if [[ -f "${out_file}" ]]; then
    if command -v owe >/dev/null 2>&1 && owe status >/dev/null 2>&1; then
      owe set "${out_file}" >/dev/null 2>&1 || true
    elif command -v omarchy-theme-bg-set >/dev/null 2>&1; then
      omarchy-theme-bg-set "${out_file}" >/dev/null 2>&1 || true
    fi
  fi
}

# ── Plymouth bootsplash & SDDM login theme sync ─────────────────────────────
sync_boot_and_login() {
  local helper="/usr/local/bin/omarchy-boot-theme-sync"
  [[ -x "${helper}" ]] || return 0
  command -v pkexec >/dev/null 2>&1 || return 0

  local slug="${THEME_SLUG,,}"
  local cur_plymouth="" need_sync=0
  cur_plymouth="$(plymouth-set-default-theme 2>/dev/null || true)"

  case "${slug}" in
    orion-n5)
      if [[ -d /usr/share/plymouth/themes/orion-n5 && "${cur_plymouth}" != "orion-n5" ]]; then
        need_sync=1
      fi
      if [[ -d /usr/share/sddm/themes/orion-n5 && ! -f /etc/sddm.conf.d/orion-n5-theme.conf ]]; then
        need_sync=1
      fi
      ;;
    arasaka-corp)
      if [[ -d /usr/share/plymouth/themes/arasaka-terminal && "${cur_plymouth}" != "arasaka-terminal" ]]; then
        need_sync=1
      fi
      if [[ -f /etc/sddm.conf.d/orion-n5-theme.conf ]]; then
        need_sync=1
      fi
      ;;
    *)
      if [[ "${cur_plymouth}" == "orion-n5" || "${cur_plymouth}" == "arasaka-terminal" ]]; then
        need_sync=1
      fi
      if [[ -f /etc/sddm.conf.d/orion-n5-theme.conf ]]; then
        need_sync=1
      fi
      ;;
  esac

  if (( need_sync == 1 )); then
    pkexec "${helper}" "${slug}" >/dev/null 2>&1 || true
  fi
}

fit_wallpaper_to_screen
sync_boot_and_login
