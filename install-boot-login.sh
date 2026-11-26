#!/usr/bin/env bash
# Install Orion N5 Plymouth (bootsplash/restart/shutdown) and SDDM (login) themes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi

echo "==> Installing SDDM login theme to /usr/share/sddm/themes/orion-n5 ..."
mkdir -p /usr/share/sddm/themes/orion-n5
cp -r "${SCRIPT_DIR}/sddm/"* /usr/share/sddm/themes/orion-n5/
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/orion-n5-theme.conf <<'CONF'
[Theme]
Current=orion-n5
CONF

echo "==> Installing Plymouth boot/restart/shutdown theme to /usr/share/plymouth/themes/orion-n5 ..."
mkdir -p /usr/share/plymouth/themes/orion-n5
cp -r "${SCRIPT_DIR}/plymouth/"* /usr/share/plymouth/themes/orion-n5/

if command -v plymouth-set-default-theme >/dev/null 2>&1; then
  plymouth-set-default-theme -R orion-n5
  echo "==> Plymouth theme set to orion-n5 and initramfs rebuilt."
else
  echo "==> Note: plymouth is not installed on this machine; files were staged in /usr/share/plymouth/themes/orion-n5."
fi

echo "==> Installing /usr/local/bin/omarchy-boot-theme-sync helper ..."
cat > /usr/local/bin/omarchy-boot-theme-sync <<'HELPER'
#!/usr/bin/env bash
set -euo pipefail

THEME_SLUG="${1,,}"
SDDM_ORION_CONF="/etc/sddm.conf.d/orion-n5-theme.conf"

set_plymouth() {
  local target="$1"
  command -v plymouth-set-default-theme >/dev/null 2>&1 || return 0
  [[ -d "/usr/share/plymouth/themes/${target}" ]] || return 0
  local current
  current="$(plymouth-set-default-theme 2>/dev/null || true)"
  if [[ "${current}" != "${target}" ]]; then
    plymouth-set-default-theme -R "${target}"
    if command -v limine-mkinitcpio >/dev/null 2>&1; then
      limine-mkinitcpio >/dev/null 2>&1 || true
    fi
  fi
}

case "${THEME_SLUG}" in
  orion-n5)
    if [[ -d /usr/share/sddm/themes/orion-n5 ]]; then
      mkdir -p /etc/sddm.conf.d
      cat > "${SDDM_ORION_CONF}" <<'CONF'
[Theme]
Current=orion-n5
CONF
    fi
    set_plymouth "orion-n5"
    ;;
  arasaka-corp)
    rm -f "${SDDM_ORION_CONF}"
    set_plymouth "arasaka-terminal"
    ;;
  *)
    rm -f "${SDDM_ORION_CONF}"
    current="$(plymouth-set-default-theme 2>/dev/null || true)"
    if [[ "${current}" == "orion-n5" || "${current}" == "arasaka-terminal" ]]; then
      set_plymouth "omarchy"
    fi
    ;;
esac
HELPER
chmod 755 /usr/local/bin/omarchy-boot-theme-sync

echo "==> Done! SDDM and Plymouth Orion N5 themes installed."
