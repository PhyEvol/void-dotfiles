#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# bootstrap.sh - prepara Void Linux para el escritorio de estos dotfiles.
#
# Uso:
#   sudo ./bootstrap.sh              # paquetes base + servicios
#   sudo ./bootstrap.sh --full       # instala también el snapshot completo
#   sudo ./bootstrap.sh --flatpak    # instala las apps Flatpak de Flathub
#   sudo ./bootstrap.sh --cups       # activa CUPS
#   sudo ./bootstrap.sh --libvirt    # activa libvirt
#   ./bootstrap.sh --dry-run         # muestra las acciones sin ejecutarlas
# ---------------------------------------------------------------------------
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=0
FULL=0
FLATPAK=0
CUPS=0
LIBVIRT=0
TARGET_USER=""

usage() {
  cat <<'EOF'
Uso: sudo ./bootstrap.sh [opciones]

Opciones:
  --user NAME  Usuario al que aplicar grupos y shell (por defecto: $SUDO_USER).
  --full       Instala packages/void-full.txt (snapshot completo).
  --flatpak    Instala las apps de packages/flatpak.txt desde Flathub.
  --cups       Activa el servicio CUPS.
  --libvirt    Activa el servicio libvirtd.
  --dry-run    Muestra las acciones sin modificar el sistema.
  -h, --help   Muestra esta ayuda.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --user)
      [ "$#" -ge 2 ] || { echo "Falta el nombre de usuario tras --user" >&2; exit 1; }
      TARGET_USER="$2"
      shift
      ;;
    --full) FULL=1 ;;
    --flatpak) FLATPAK=1 ;;
    --cups) CUPS=1 ;;
    --libvirt) LIBVIRT=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opción desconocida: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

log() { printf '%s\n' "$*"; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

if [ "$DRY_RUN" -eq 0 ] && [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "Ejecuta este script con sudo: sudo $0 $*" >&2
  exit 1
fi

# shellcheck disable=SC1091
. /etc/os-release 2>/dev/null || true
if [ "${ID:-}" != "void" ]; then
  echo "Este script está pensado para Void Linux (ID=void no encontrado en /etc/os-release)." >&2
  exit 1
fi

if [ -z "$TARGET_USER" ]; then
  TARGET_USER="${SUDO_USER:-}"
fi
if [ -z "$TARGET_USER" ] && [ "$(id -u)" -ne 0 ]; then
  TARGET_USER="$(id -un)"
fi
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
  echo "No puedo detectar tu usuario normal. Usa: sudo ./bootstrap.sh --user TU_USUARIO" >&2
  exit 1
fi
if ! id -u "$TARGET_USER" >/dev/null 2>&1; then
  echo "El usuario '$TARGET_USER' no existe." >&2
  exit 1
fi

get_user_home() {
  awk -F: -v u="$1" '$1 == u { print $6 }' /etc/passwd
}

get_user_shell() {
  awk -F: -v u="$1" '$1 == u { print $7 }' /etc/passwd
}

TARGET_HOME="$(get_user_home "$TARGET_USER")"
if [ -z "$TARGET_HOME" ]; then
  echo "No encuentro el HOME de $TARGET_USER en /etc/passwd." >&2
  exit 1
fi
log "Repositorio: $REPO_DIR"
log "Usuario:     $TARGET_USER ($TARGET_HOME)"
[ "$DRY_RUN" -eq 1 ] && log "Modo:        dry-run (sin cambios)"

# ---------------------------------------------------------------------------
# Repos y paquetes
# ---------------------------------------------------------------------------
log ""
log "== Repositorios =="
run xbps-install -Syu xbps
run xbps-install -Sy void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree

LIST="$REPO_DIR/packages/void-desktop.txt"
[ "$FULL" -eq 1 ] && LIST="$REPO_DIR/packages/void-full.txt"

if [ ! -f "$LIST" ]; then
  echo "No encuentro la lista de paquetes: $LIST" >&2
  exit 1
fi

mapfile -t WANTED < <(grep -vE '^[[:space:]]*(#|$)' "$LIST")

log ""
log "== Paquetes ($(basename "$LIST")) =="
AVAILABLE=()
MISSING=0
for pkg in "${WANTED[@]}"; do
  if xbps-query -R "$pkg" 2>/dev/null | grep -q '^pkgver:'; then
    AVAILABLE+=("$pkg")
  else
    log "  omitido (no está en los repos): $pkg"
    MISSING=$((MISSING + 1))
  fi
done

if [ "${#AVAILABLE[@]}" -gt 0 ]; then
  run xbps-install -Sy "${AVAILABLE[@]}"
else
  log "  no hay paquetes disponibles para instalar"
fi

# ---------------------------------------------------------------------------
# Servicios runit
# ---------------------------------------------------------------------------
SERVICES=(dbus elogind polkitd udevd iwd bluetoothd chronyd tlp zramen sddm)
[ "$CUPS" -eq 1 ] && SERVICES+=(cupsd)
[ "$LIBVIRT" -eq 1 ] && SERVICES+=(libvirtd)

log ""
log "== Servicios =="
for svc in "${SERVICES[@]}"; do
  link="/etc/runit/runsvdir/default/$svc"
  if [ -e "$link" ] || [ -L "$link" ]; then
    log "  ya activo: $svc"
    continue
  fi
  if [ ! -d "/etc/sv/$svc" ]; then
    log "  aviso: no existe /etc/sv/$svc"
    continue
  fi
  run ln -s "/etc/sv/$svc" "$link"
  log "  activado: $svc"
done

# ---------------------------------------------------------------------------
# Grupos y shell
# ---------------------------------------------------------------------------
TARGET_GROUPS=(wheel audio video bluetooth scanner lp)
log ""
log "== Grupos de $TARGET_USER =="
for grp in "${TARGET_GROUPS[@]}"; do
  grep -q "^$grp:" /etc/group || continue
  if id -nG "$TARGET_USER" | tr ' ' '\n' | grep -qx "$grp"; then
    log "  ok: $grp"
    continue
  fi
  run usermod -aG "$grp" "$TARGET_USER"
  log "  añadido: $grp"
done

ZSH_PATH="$(command -v zsh || true)"
if [ -n "$ZSH_PATH" ]; then
  CURRENT_SHELL="$(get_user_shell "$TARGET_USER")"
  if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    log "  shell: $CURRENT_SHELL -> $ZSH_PATH"
    run chsh -s "$ZSH_PATH" "$TARGET_USER"
  else
    log "  shell: ya es zsh"
  fi
fi

# ---------------------------------------------------------------------------
# Flatpak (opcional)
# ---------------------------------------------------------------------------
if [ "$FLATPAK" -eq 1 ]; then
  log ""
  log "== Flatpak =="
  if ! command -v flatpak >/dev/null 2>&1; then
    log "  aviso: flatpak no está instalado"
  else
    run flatpak remote-add --if-not-exists flathub \
      https://flathub.org/repo/flathub.flatpakrepo
    mapfile -t APPS < <(grep -vE '^[[:space:]]*(#|$)' "$REPO_DIR/packages/flatpak.txt")
    for app in "${APPS[@]}"; do
      if flatpak info "$app" >/dev/null 2>&1; then
        log "  ok: $app"
        continue
      fi
      run flatpak install -y flathub "$app" \
        || log "  aviso: no se pudo instalar $app"
    done
  fi
fi

log ""
if [ "$DRY_RUN" -eq 1 ]; then
  log "Simulación completada. Ejecuta con sudo para aplicar."
else
  log "Sistema preparado. Cierra sesión o reinicia para aplicar grupos y servicios."
  if [ "$MISSING" -gt 0 ]; then
    log "Se omitieron $MISSING paquetes que no están en los repos."
  fi
fi
