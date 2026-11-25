#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# install.sh - instala los dotfiles en $HOME mediante symlinks.
#
# Uso:
#   ./install.sh                 # instala y hace backup de lo existente
#   ./install.sh --dry-run       # muestra qué haría, sin tocar nada
#   ./install.sh --force         # reemplaza sin backup
#   ./install.sh --no-backup     # reemplaza sin backup (igual que --force)
#   ./install.sh --set-shell     # cambia tu shell a zsh
#   ./install.sh --skip-plugins  # no clona los plugins de zsh
# ---------------------------------------------------------------------------
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$REPO_DIR/home"
DEST_HOME="${HOME:?HOME no está definido}"

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$DEST_HOME/.dotfiles-backup/$STAMP-$$"
BACKUP_USED=0

DRY_RUN=0
NO_BACKUP=0
FORCE=0
SET_SHELL=0
SKIP_PLUGINS=0

usage() {
  cat <<'EOF'
Uso: ./install.sh [opciones]

Opciones:
  --dry-run       Muestra las acciones sin modificar nada.
  --force         Reemplaza los archivos existentes sin hacer backup.
  --no-backup     Igual que --force.
  --set-shell     Cambia el shell del usuario a zsh.
  --skip-plugins  No clona zsh-autosuggestions ni zsh-syntax-highlighting.
  -h, --help      Muestra esta ayuda.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1; NO_BACKUP=1 ;;
    --no-backup) NO_BACKUP=1 ;;
    --set-shell) SET_SHELL=1 ;;
    --skip-plugins) SKIP_PLUGINS=1 ;;
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

is_linked_to() {
  [ -L "$1" ] && [ "$(readlink -f -- "$1")" = "$(readlink -f -- "$2")" ]
}

backup_path() {
  local target="$1"
  local rel="${target#"$DEST_HOME"/}"
  local dest="$BACKUP_DIR/$rel"

  BACKUP_USED=1
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] backup %s -> %s\n' "$target" "$dest"
    return 0
  fi
  mkdir -p -- "$(dirname -- "$dest")"
  mv -- "$target" "$dest"
  log "  backup: $target -> $dest"
}

link_one() {
  local src="$1"
  local rel="${src#"$SRC_DIR"/}"
  local target="$DEST_HOME/$rel"

  # Los .example se quedan como documentación; no se enlazan.
  case "$rel" in
    *.example) return 0 ;;
  esac

  if is_linked_to "$target" "$src"; then
    log "  ok: $rel"
    return 0
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ "$NO_BACKUP" -eq 1 ]; then
      log "  reemplazando: $target"
      run rm -rf -- "$target"
    else
      backup_path "$target"
    fi
  fi

  run mkdir -p -- "$(dirname -- "$target")"
  run ln -s -- "$src" "$target"
  log "  enlazado: $rel"
}

install_wallpapers() {
  local src_dir="$REPO_DIR/assets/wallpapers"
  local dest_dir="$DEST_HOME/Pictures/Wallpapers"
  local f target

  [ -d "$src_dir" ] || return 0

  log ""
  log "== Wallpapers =="
  run mkdir -p -- "$dest_dir"
  for f in "$src_dir"/*; do
    [ -e "$f" ] || continue
    target="$dest_dir/$(basename -- "$f")"
    if [ -e "$target" ] && [ "$FORCE" -ne 1 ]; then
      log "  ya existe: $target"
      continue
    fi
    run cp -- "$f" "$target"
    log "  copiado: $(basename -- "$f")"
  done
}

install_plugin() {
  local name="$1" url="$2" commit="$3"
  local dir="$DEST_HOME/.zsh/$name"

  if [ -d "$dir/.git" ]; then
    log "  ok: $name"
    return 0
  fi

  if [ -e "$dir" ]; then
    log "  aviso: $dir existe y no es un repo git; se omite"
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] git clone %s %s\n' "$url" "$dir"
    printf '[dry-run] git -C %s checkout %s\n' "$dir" "$commit"
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    log "  aviso: git no está instalado; instala los plugins manualmente"
    return 0
  fi

  run mkdir -p -- "$DEST_HOME/.zsh"
  if git clone --quiet "$url" "$dir"; then
    git -C "$dir" checkout --quiet "$commit" 2>/dev/null \
      || log "  aviso: no se pudo fijar el commit $commit en $name"
    log "  instalado: $name"
  else
    log "  aviso: no se pudo clonar $name (¿sin red?)"
  fi
}

install_plugins() {
  log ""
  log "== Plugins de zsh =="
  install_plugin zsh-autosuggestions \
    https://github.com/zsh-users/zsh-autosuggestions.git 85919cd
  install_plugin zsh-syntax-highlighting \
    https://github.com/zsh-users/zsh-syntax-highlighting.git e6683f2
}

set_shell() {
  [ "$SET_SHELL" -eq 1 ] || return 0

  local zsh_path current
  zsh_path="$(command -v zsh || true)"
  if [ -z "$zsh_path" ]; then
    log "  aviso: zsh no está instalado; no se cambia el shell"
    return 0
  fi

  current="$(awk -F: -v u="$(id -un)" '$1 == u { print $7 }' /etc/passwd)"
  if [ "$current" = "$zsh_path" ]; then
    log "  ok: ya usas $zsh_path"
    return 0
  fi

  log "  cambiando shell a $zsh_path"
  run chsh -s "$zsh_path" "$(id -un)"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if [ ! -d "$SRC_DIR" ]; then
  echo "No encuentro $SRC_DIR. ¿Estás ejecutando el script desde el repo?" >&2
  exit 1
fi

log "Dotfiles: $REPO_DIR"
log "Destino:  $DEST_HOME"
[ "$DRY_RUN" -eq 1 ] && log "Modo:     dry-run (sin cambios)"

log ""
log "== Enlazando archivos =="
while IFS= read -r -d '' src; do
  link_one "$src"
done < <(find "$SRC_DIR" -type f -print0 | sort -z)

install_wallpapers
[ "$SKIP_PLUGINS" -eq 0 ] && install_plugins
set_shell

log ""
if [ "$DRY_RUN" -eq 1 ]; then
  log "Simulación completada. Ejecuta sin --dry-run para aplicar."
else
  log "Listo. Reinicia la sesión (o pulsa SUPER+r en mango) para aplicar."
  if [ "$BACKUP_USED" -eq 1 ]; then
    log "Backup: $BACKUP_DIR"
  fi
fi
