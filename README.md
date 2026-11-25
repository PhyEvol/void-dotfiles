# Dotfiles de affe

Configuración personal de **Void Linux** con **mango** como compositor Wayland,
**noctalia** como shell/barra y **alacritty** como terminal. El objetivo es poder
reinstalar el escritorio en pocos minutos y mantener todo versionado.

![Void Linux](https://img.shields.io/badge/Void-Linux-478061?style=flat-square)
![Wayland](https://img.shields.io/badge/Wayland-mango-89cc66?style=flat-square)
![Shell](https://img.shields.io/badge/shell-zsh-f3f2f2?style=flat-square)

## Qué incluye

| Área | Archivos |
|---|---|
| Shell | `.zshrc`, `starship.toml` |
| Compositor | `.config/mango/config.toml` |
| Barra / shell | `.config/noctalia/config.toml` |
| Terminal | `.config/alacritty/` (tema incluido) |
| TUI | `fastfetch`, `btop`, `cava`, `micro`, `helix` |
| Apps | `mpv`, `zed`, `zathura`, `mimeapps.list`, `kdeglobals` |
| Scripts | `.local/bin/mango-sound`, `.local/bin/scratch-term` |
| Fondos | `assets/wallpapers/` (3 favoritos) |
| Sistema | `packages/` + `bootstrap.sh` |

**No incluido a propósito:** claves SSH, tokens, historiales, cachés, datos de
Steam/Wine/Flatpak, el cursor `MeguminCursor` (94 MB) y el script
`~/bin/blizz-tunnel` (contiene alias e IPs internas).

## Instalación rápida

```sh
git clone https://github.com/PhyEvol/void-dotfiles.git ~/Projects/Dotfiles
cd ~/Projects/Dotfiles

# 1. Paquetes y servicios (Void, requiere sudo)
sudo ./bootstrap.sh

# 2. Revisa qué hará y luego aplica
./install.sh --dry-run
./install.sh
```

Cierra sesión y vuelve a entrar (o reinicia) para que se apliquen grupos,
servicios y el shell.

### Opciones de `bootstrap.sh`

```sh
sudo ./bootstrap.sh              # paquetes base del escritorio
sudo ./bootstrap.sh --full       # snapshot completo de paquetes manuales
sudo ./bootstrap.sh --flatpak    # apps de Flathub
sudo ./bootstrap.sh --cups       # activa CUPS
sudo ./bootstrap.sh --libvirt    # activa libvirt
./bootstrap.sh --dry-run         # simulación sin sudo
```

### Opciones de `install.sh`

```sh
./install.sh                 # symlinks + backup automático
./install.sh --dry-run       # muestra las acciones
./install.sh --force         # reemplaza sin backup
./install.sh --set-shell     # cambia tu shell a zsh
./install.sh --skip-plugins  # no clona plugins de zsh
```

Los archivos existentes se guardan en `~/.dotfiles-backup/<fecha>/`.
Los plugins `zsh-autosuggestions` y `zsh-syntax-highlighting` se clonan en
`~/.zsh/` con un commit fijado.

## Pasos manuales

### 1. Nya

### 2. Tema de SDDM

El tema `sword` vive en `/usr/share/sddm/themes` y no forma parte del repo.
Si quieres replicarlo, cópialo aparte con permisos de root.

### 3. Monitor y teclado

Ajusta `[[rule.monitor_rule]]` en `~/.config/mango/config.toml` según tu
pantalla (`wlr-randr`). El layout de teclado está en `latam`.

### 4. Si tu usuario no es `affe`

`install.sh` detecta `$HOME` distinto de `/home/affe` y reemplaza las rutas
absolutas en `mango`, `noctalia`, `fastfetch` y `.zshrc`. Como esos archivos son
symlinks, el cambio se refleja en el repo: revísalo con `git diff` antes de
commitear.

## Atajos principales de mango

| Atajo | Acción |
|---|---|
| `SUPER + Return` | Alacritty |
| `SUPER + d` | Lanzador de noctalia |
| `SUPER + q` | Cerrar ventana |
| `SUPER + r` | Recargar configuración |
| `SUPER + h/j/k/l` | Mover foco |
| `SUPER + 1..9` | Ir al tag |
| `SUPER + SHIFT + 1..9` | Mover ventana al tag |
| `SUPER + f` | Pantalla completa |
| `SUPER + SHIFT + space` | Flotante |
| `SUPER + SHIFT + s` | Captura de área al portapapeles |
| `Print` | Captura de pantalla completa |
| `SUPER + SHIFT + p` | Sonido `mango-sound` |

## Estructura

```
.
├── install.sh              # symlinks, backups, plugins, wallpapers
├── bootstrap.sh            # paquetes y servicios de Void
├── gitconfig.example
├── packages/
│   ├── void-desktop.txt    # lista curada
│   ├── void-full.txt       # snapshot completo
│   └── flatpak.txt
├── home/                   # se enlaza dentro de $HOME
│   ├── .zshrc
│   ├── .config/...
│   ├── .local/bin/...
└── assets/wallpapers/
```
