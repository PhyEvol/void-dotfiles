# void-dotfiles

Mis dotfiles de Void Linux. Los uso a diario en un Aspire AL14-31P.

- WM: mango
- Barra/shell: noctalia
- Terminal: alacritty
- Shell: zsh + starship
- Editor: helix (y micro/zed para cosas puntuales)
- Fuente: Iosevka

## Instalación

En un Void que ya funciona:

```sh
git clone https://github.com/PhyEvol/void-dotfiles.git ~/Projects/Dotfiles
cd ~/Projects/Dotfiles
./install.sh
```

`install.sh` crea symlinks en `$HOME` y guarda lo que ya existiera en
`~/.dotfiles-backup/<fecha>/`. También copia los fondos a `~/Pictures/Wallpapers`
y clona los plugins de zsh.

Si estás reinstalando desde cero:

```sh
sudo ./bootstrap.sh
./install.sh
```

`bootstrap.sh` instala lo de `packages/void-desktop.txt`, activa los servicios
(sddm, iwd, bluetoothd, tlp, zramen, etc.) y agrega tu usuario a los grupos.
Con `--full` usa el snapshot completo de paquetes. Si lo ejecutas desde una
sesión root sin `sudo`, indica tu usuario con `--user TU_USUARIO`.

Antes de aplicar nada puedes ver qué va a hacer:

```sh
./install.sh --dry-run
```

## Git

El repo instala `~/.gitconfig` con ajustes comunes. La identidad y las
credenciales van aparte, en `~/.gitconfig.local`, que no se sube:

```ini
[user]
	name = Tu Nombre
	email = tu@correo
```

## Notas

- Las configuraciones usan `~` y `$HOME`; no hay rutas con un usuario concreto.
  Puedes clonar el repo en cualquier carpeta y usar cualquier nombre de usuario.
- El cursor `MeguminCursor` no está en el repo porque pesa ~94 MB. Está en
  `~/.local/share/icons` y hay que copiarlo aparte.
- `~/bin/blizz-tunnel` tampoco está: tiene alias e IPs internas.
- `packages/void-desktop.txt` trae Intel por defecto. Si tienes AMD o NVIDIA,
  comenta el bloque de Intel y descomenta el tuyo antes de ejecutar
  `bootstrap.sh`.
- mango viene con layout `latam` y touchpad activado. Si no te sirve, cambia
  `xkb_rules_layout` en `home/.config/mango/config.toml`.
- `mango-sound` usa `$MANGO_SOUND`, un archivo en `~/Music` o la campana del
  sistema. También puedes pasarle una ruta: `mango-sound ~/audio.mp3`.
- Noctalia regenera los temas de alacritty, btop, helix, qt y starship cuando
  cambias el tema. Si editas esos archivos a mano, pueden sobrescribirse.
- El tema de SDDM y el cursor son ajustes manuales.
- `scratch-term` es de cuando usaba sway; mango ya tiene scratchpad nativo.

## Atajos

| Atajo | Acción |
|---|---|
| `SUPER + Return` | alacritty |
| `SUPER + d` | lanzador de noctalia |
| `SUPER + q` | cerrar ventana |
| `SUPER + r` | recargar mango |
| `SUPER + h/j/k/l` | mover foco |
| `SUPER + 1..9` | ir al tag |
| `SUPER + SHIFT + 1..9` | mover ventana al tag |
| `SUPER + f` | pantalla completa |
| `SUPER + SHIFT + space` | flotante |
| `SUPER + SHIFT + s` | captura de área |
| `Print` | captura de pantalla completa |
| `SUPER + SHIFT + p` | mango-sound |

## Estructura

```
install.sh              # symlinks, backups, plugins, wallpapers
bootstrap.sh            # paquetes y servicios de Void
packages/               # listas de paquetes
home/                   # lo que se enlaza en $HOME
assets/wallpapers/      # fondos
```
