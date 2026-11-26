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

echo "==> Done! SDDM and Plymouth Orion N5 themes installed."
