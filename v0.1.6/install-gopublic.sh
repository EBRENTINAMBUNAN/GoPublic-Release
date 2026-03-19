#!/usr/bin/env bash
set -euo pipefail

COMMAND_NAME="gopublic"
BINARY_NAME=gopublic-linux-amd64-v0.1.6
INSTALL_PATH="/usr/local/bin/$COMMAND_NAME"
CLOUDFLARE_KEY_URL="https://pkg.cloudflare.com/cloudflare-main.gpg"
CLOUDFLARE_KEYRING="/usr/share/keyrings/cloudflare-main.gpg"
CLOUDFLARE_LIST="/etc/apt/sources.list.d/cloudflared.list"
CLOUDFLARE_REPO_LINE='deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main'

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

ensure_debian_like() {
  if [[ ! -f /etc/os-release ]]; then
    echo "[ERROR] /etc/os-release tidak ditemukan." >&2
    exit 1
  fi

  local ids
  ids="$(. /etc/os-release && printf '%s %s' "${ID:-}" "${ID_LIKE:-}")"
  case " $ids " in
    *" debian "*|*" ubuntu "*|*" raspbian "*) ;;
    *)
      echo "[ERROR] Installer release ini hanya mendukung Debian/Ubuntu." >&2
      exit 1
      ;;
  esac
}

verify_checksum() {
  local checksum_path="$1"
  if [[ -f "$checksum_path" ]]; then
    (cd "$SCRIPT_DIR" && sha256sum -c "$(basename "$checksum_path")")
  fi
}

install_cloudflare_repo() {
  install -d -m 755 /usr/share/keyrings
  curl -fsSL "$CLOUDFLARE_KEY_URL" -o "$CLOUDFLARE_KEYRING"
  chmod 644 "$CLOUDFLARE_KEYRING"
  printf '%s\n' "$CLOUDFLARE_REPO_LINE" > "$CLOUDFLARE_LIST"
}

resolve_target_user() {
  if [[ -n "${GOPUBLIC_TARGET_USER:-}" ]]; then
    printf '%s\n' "$GOPUBLIC_TARGET_USER"
    return 0
  fi
  if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    printf '%s\n' "$SUDO_USER"
    return 0
  fi
  if [[ -n "${USER:-}" && "$USER" != "root" ]]; then
    printf '%s\n' "$USER"
    return 0
  fi
  return 1
}

resolve_target_home() {
  if [[ -n "${GOPUBLIC_TARGET_HOME:-}" ]]; then
    printf '%s\n' "$GOPUBLIC_TARGET_HOME"
    return 0
  fi
  local target_user="${1:-}"
  if [[ -z "$target_user" ]]; then
    return 1
  fi
  getent passwd "$target_user" | cut -d: -f6
}

legacy_main_path_from_launcher() {
  local launcher_path="$1"
  if [[ ! -f "$launcher_path" ]]; then
    return 0
  fi
  grep -Eo '/[^[:space:]]+/main\.py' "$launcher_path" | tail -n 1 || true
}

migrate_legacy_registry() {
  local launcher_path="$1"
  local target_home="$2"
  local target_user="$3"
  if [[ -z "$target_home" ]]; then
    return 0
  fi

  local main_path legacy_dir legacy_registry state_dir target_registry
  main_path="$(legacy_main_path_from_launcher "$launcher_path")"
  if [[ -z "$main_path" ]]; then
    return 0
  fi

  legacy_dir="$(dirname "$main_path")"
  legacy_registry="$legacy_dir/projects.json"
  state_dir="$target_home/.config/gopublic"
  target_registry="$state_dir/projects.json"

  if [[ -r "$legacy_registry" && ! -e "$target_registry" ]]; then
    install -d -m 755 "$state_dir"
    install -m 644 "$legacy_registry" "$target_registry"
    if [[ -n "$target_user" ]]; then
      chown "$target_user:$target_user" "$state_dir" "$target_registry" || true
    fi
    echo "[INFO] Registry lama dimigrasikan ke $target_registry"
    return 0
  fi

  if [[ -e "$legacy_registry" && ! -r "$legacy_registry" ]]; then
    echo "[WARN] Registry lama terdeteksi di $legacy_registry tetapi tidak bisa dibaca untuk migrasi otomatis."
  fi
}

refresh_user_launcher() {
  local launcher_path="$1"
  local target_user="$2"
  if [[ ! -f "$launcher_path" ]] || ! grep -q 'main.py' "$launcher_path"; then
    return 0
  fi

  local backup_path="$launcher_path.source-launcher.bak"
  cp -a "$launcher_path" "$backup_path" || true
  cat > "$launcher_path" <<EOF
#!/usr/bin/env bash
exec "$INSTALL_PATH" "\$@"
EOF
  chmod 755 "$launcher_path"
  if [[ -n "$target_user" ]]; then
    chown "$target_user:$target_user" "$launcher_path" "$backup_path" || true
  fi
  echo "[INFO] Launcher lama diperbarui: $launcher_path -> $INSTALL_PATH"
}

SYSTEM_DEPS=1
VERIFY=1
ORIGINAL_ARGS=("$@")

while [[ $# -gt 0 ]]; do
  case "$1" in
    --binary-only)
      SYSTEM_DEPS=0
      shift
      ;;
    --skip-verify)
      VERIFY=0
      shift
      ;;
    -h|--help)
      cat <<'EOF'
GoPublic public installer

Usage:
  sudo bash ./install-gopublic.sh

Options:
  --binary-only  Hanya pasang binary ke /usr/local/bin/gopublic
  --skip-verify  Lewati verifikasi SHA-256 jika file checksum tersedia
EOF
      exit 0
      ;;
    *)
      echo "[ERROR] Opsi tidak dikenal: $1" >&2
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_PATH="$SCRIPT_DIR/$BINARY_NAME"
CHECKSUM_PATH="$SCRIPT_DIR/$BINARY_NAME.sha256"

if [[ ! -f "$BINARY_PATH" ]]; then
  echo "[ERROR] Binary release tidak ditemukan: $BINARY_PATH" >&2
  exit 1
fi

require_root "${ORIGINAL_ARGS[@]}"
need_cmd sha256sum
ensure_debian_like

TARGET_USER="$(resolve_target_user || true)"
TARGET_HOME="$(resolve_target_home "$TARGET_USER" || true)"
LEGACY_USER_LAUNCHER=""
if [[ -n "$TARGET_HOME" ]]; then
  LEGACY_USER_LAUNCHER="$TARGET_HOME/bin/$COMMAND_NAME"
fi

if [[ "$VERIFY" -eq 1 ]]; then
  verify_checksum "$CHECKSUM_PATH"
fi

if [[ "$SYSTEM_DEPS" -eq 1 ]]; then
  need_cmd apt-get
  apt-get update
  apt-get install -y ca-certificates curl gnupg nginx
  install_cloudflare_repo
  apt-get update
  apt-get install -y cloudflared
  if command -v systemctl >/dev/null 2>&1; then
    systemctl enable --now nginx || true
  fi
fi

install -m 755 "$BINARY_PATH" "$INSTALL_PATH"
migrate_legacy_registry "$LEGACY_USER_LAUNCHER" "$TARGET_HOME" "$TARGET_USER"
refresh_user_launcher "$LEGACY_USER_LAUNCHER" "$TARGET_USER"

echo
echo "Instalasi GoPublic selesai."
echo "Binary  : $INSTALL_PATH"
echo "Next    : gopublic"
echo "Docs    : gopublic menu"
