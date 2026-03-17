#!/usr/bin/env bash
set -euo pipefail

INSTALL_PATH="/usr/local/bin/gopublic"
CLOUDFLARE_KEYRING="/usr/share/keyrings/cloudflare-main.gpg"
CLOUDFLARE_LIST="/etc/apt/sources.list.d/cloudflared.list"
PURGE_DEPS=0
ORIGINAL_ARGS=("$@")

require_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    return 0
  fi
  exec sudo -E bash "$0" "$@"
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERROR] Perintah '$1' tidak ditemukan." >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --purge-system-deps)
      PURGE_DEPS=1
      shift
      ;;
    -h|--help)
      cat <<'EOF'
GoPublic public uninstaller

Usage:
  sudo bash ./uninstall-gopublic.sh

Options:
  --purge-system-deps  Hapus juga nginx, cloudflared, dan repo Cloudflare
EOF
      exit 0
      ;;
    *)
      echo "[ERROR] Opsi tidak dikenal: $1" >&2
      exit 1
      ;;
  esac
done

require_root "${{ORIGINAL_ARGS[@]}}"

if [[ -e "$INSTALL_PATH" ]]; then
  rm -f "$INSTALL_PATH"
fi

if [[ "$PURGE_DEPS" -eq 1 ]]; then
  need_cmd apt-get
  if command -v systemctl >/dev/null 2>&1; then
    systemctl disable --now cloudflared 2>/dev/null || true
    systemctl disable --now nginx 2>/dev/null || true
  fi
  apt-get purge -y cloudflared nginx nginx-common nginx-core nginx-full nginx-light nginx-extras || true
  apt-get autoremove -y || true
  rm -f "$CLOUDFLARE_LIST" "$CLOUDFLARE_KEYRING"
  apt-get update || true
fi

echo
echo "GoPublic berhasil dicabut."
echo "Binary  : $INSTALL_PATH"
if [[ "$PURGE_DEPS" -eq 1 ]]; then
  echo "System  : nginx dan cloudflared ikut dipurge"
else
  echo "System  : dependency sistem dipertahankan"
fi
