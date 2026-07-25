# Full install guide — Fedora + Hyprland + Caelestia + this rice

Step-by-step for friends on **Fedora** who want the same stack:

1. **Hyprland** (window manager, Lua config, 0.56+)
2. **Quickshell** (shell runtime)
3. **Caelestia** shell + CLI (desktop UI)
4. **This repo** (overlay: liquid glass, minimize, video walls, Notifications tab, …)

Tested on **Fedora 44**, Hyprland `0.56` from COPR `sdegler/hyprland`, Quickshell from COPR `errornointernet/quickshell`.

> This is **not** a full desktop distro. You need a working Fedora install with a display manager (GDM, SDDM, etc.) or you can start Hyprland from a TTY.

---

## Overview (what goes where)

| Piece | Role | Typical path |
|-------|------|----------------|
| Hyprland | Compositor / WM | `/usr/bin/Hyprland`, config `~/.config/hypr/` |
| Quickshell | QML shell engine | `/usr/bin/qs` / `quickshell` |
| Caelestia shell | UI (bar, dashboard, launcher, notifs) | `~/.config/quickshell/caelestia/` |
| Caelestia CLI | `caelestia` control script | `~/.local/bin/caelestia` |
| This rice | Config + shell **overlay** | applied by `./install.sh` |

**Order matters:** Hyprland → Quickshell → Caelestia shell+CLI → this overlay.

---

## 0. Prerequisites

```bash
sudo dnf update -y
sudo dnf install -y git curl wget cmake ninja-build gcc g++ make \
  python3 python3-pip python3-devel \
  wayland-devel wayland-protocols-devel \
  qt6-qtbase-devel qt6-qtdeclarative-devel \
  pipewire pipewire-pulseaudio wireplumber \
  NetworkManager lm_sensors brightnessctl \
  fish socat wl-clipboard cliphist grim slurp \
  fuzzel foot playerctl pavucontrol \
  mpv ffmpeg
```

Optional but useful:

```bash
# NVIDIA proprietary stack (if you use NVIDIA) — use the path you already use
# (akmod-nvidia / RPM Fusion). Wayland needs GBM + recent drivers.

# fonts used by Caelestia-style UIs
sudo dnf install -y google-noto-sans-fonts google-noto-emoji-fonts
# Install a Nerd Font (e.g. Caskaydia Cove) and Material Symbols yourself if missing.
```

Ensure `~/.local/bin` is on your `PATH`:

```bash
# bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# zsh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

---

## 1. Install Hyprland (Fedora)

### 1.1 Enable a Hyprland COPR

This machine uses **sdegler/hyprland** (Hyprland 0.56 with Lua config):

```bash
sudo dnf copr enable sdegler/hyprland
sudo dnf install -y hyprland hyprland-uwsm xdg-desktop-portal-hyprland \
  hyprlock hypridle hyprpicker hyprland-guiutils
```

Alternative COPRs exist (e.g. `ashbuk/Hyprland-Fedora`, `solopasha/hyprland`).  
**Do not enable multiple Hyprland COPRs at once** — package conflicts.

Check:

```bash
hyprland --version
# expect something like Hyprland 0.56.x
```

### 1.2 Session / login

After install, **log out** and pick **Hyprland** (or **Hyprland (uwsm)**) from your display manager.

First boot may use a default config. That is fine — this rice replaces `~/.config/hypr` later.

### 1.3 NVIDIA notes (optional)

If blur or layer rules misbehave on NVIDIA:

- Prefer GBM backend / recent drivers
- This rice sets env hints in `~/.config/hypr/hyprland/env.lua` after overlay install
- Glass blur is applied to **UI layers only**, not the wallpaper

---

## 2. Install Quickshell

Caelestia needs **Quickshell**. On this Fedora setup:

```bash
sudo dnf copr enable errornointernet/quickshell
sudo dnf install -y quickshell
```

Check:

```bash
qs --version   # or: quickshell --version
which qs
```

> Upstream Caelestia docs often say **quickshell-git**. The COPR package may lag slightly; if the shell fails to start after Caelestia install, rebuild/update Quickshell or follow [quickshell.outfoxxed.me](https://quickshell.outfoxxed.me).

---

## 3. Install Caelestia CLI

The `caelestia` command talks to the shell (start/stop, wallpaper, scheme, …).

### Manual (Fedora / pip user install)

```bash
# runtime deps for CLI features
sudo dnf install -y libnotify grim slurp wl-clipboard cliphist fuzzel

# build tools for the wheel
pip install --user build installer hatch hatch-vcs

git clone https://github.com/caelestia-dots/cli.git /tmp/caelestia-cli
cd /tmp/caelestia-cli
python3 -m build --wheel
python3 -m installer --prefix="$HOME/.local" dist/*.whl
# or: pip install --user dist/*.whl

hash -r
caelestia -h
```

Official docs: [caelestia-dots/cli](https://github.com/caelestia-dots/cli).

### Extra CLI deps (recommended)

```bash
sudo dnf install -y swappy  # screenshot editor if packaged
# gpu-screen-recorder, dart-sass, papirus-folders — optional theming extras
```

---

## 4. Install Caelestia shell

The shell source lives under Quickshell’s config dir and is built with CMake.

### 4.1 Clone + build

```bash
mkdir -p ~/.config/quickshell
cd ~/.config/quickshell

# Fresh install only — if caelestia already exists, skip clone or back it up first
git clone https://github.com/caelestia-dots/shell.git caelestia
cd caelestia
```

Shell dependencies (Fedora package names; adjust if a name differs):

```bash
sudo dnf install -y ddcutil brightnessctl aubio aubio-devel \
  qalculate-gtk libqalculate libqalculate-devel \
  pipewire-devel glibc-devel \
  qt6-qtbase qt6-qtdeclarative \
  cmake ninja-build
# libcava / cava — install if available, or build from source if shell needs it
```

Build & install plugin / libs:

```bash
cd ~/.config/quickshell/caelestia

cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/ \
  -DINSTALL_QSCONFDIR="$HOME/.config/quickshell/caelestia"

cmake --build build
sudo cmake --install build
sudo chown -R "$USER:$USER" ~/.config/quickshell/caelestia
```

Official manual steps: [caelestia-dots/shell#manual-installation](https://github.com/caelestia-dots/shell#manual-installation).

### 4.2 Smoke-test the shell

From an existing Hyprland session (or after login):

```bash
caelestia shell -d
# if that fails:
qs -c caelestia
```

You should see the bar / drawers. Kill with:

```bash
caelestia shell -k
```

### 4.3 User config dir

```bash
mkdir -p ~/.config/caelestia
# shell.json is optional until this rice installs one
```

Wallpapers default to `~/Pictures/Wallpapers` (change later in `shell.json`).

---

## 5. Install **this rice** (liquid glass + extras)

Only after Hyprland + Quickshell + Caelestia shell exist:

```bash
git clone https://github.com/iotserver24/hyprland-caelestia-fedora.git
cd hyprland-caelestia-fedora
chmod +x install.sh
./install.sh
```

Installer flags:

```bash
./install.sh --yes      # accept prompts (still careful with overwrites)
./install.sh --dry-run  # print actions only
```

### What `install.sh` does

1. Optionally installs helper packages via `dnf`
2. Installs scripts → `~/.local/bin/`  
   - `hypr-minimize`  
   - `video-wallpaper`  
   - `liquid-glass`
3. Builds `~/.local/lib/hypr-minifix.so` (titlebar minimize preload)
4. Copies Hyprland Lua config → `~/.config/hypr/` (with backup)
5. Copies Caelestia user files → `~/.config/caelestia/`  
   (`hypr-user.lua`, `hypr-vars.lua`, `shell.json`)
6. Overlays QML onto `~/.config/quickshell/caelestia/`  
   (liquid glass components, Notifications tab, video wallpaper UI, …)
7. Turns **liquid glass on** by default

Existing configs are backed up as `*.bak.<timestamp>`.

### Apply without full reinstall (manual)

```
config/hypr/           →  ~/.config/hypr/
config/caelestia/      →  ~/.config/caelestia/
scripts/*              →  ~/.local/bin/
minifix/hypr-minifix.c →  build to ~/.local/lib/hypr-minifix.so
shell-overlay/*        →  merge into ~/.config/quickshell/caelestia/
```

```bash
mkdir -p ~/.local/lib
gcc -shared -fPIC -O2 -o ~/.local/lib/hypr-minifix.so \
  minifix/hypr-minifix.c -ldl -lwayland-client
```

---

## 6. First launch after the rice

```bash
# reload Hyprland config
hyprctl reload

# restart shell so QML overlay loads
caelestia shell -k
sleep 0.5
caelestia shell -d
```

Or **log out → log in** to Hyprland.

### Verify liquid glass

```bash
liquid-glass status
# expect: on

# toggle
liquid-glass off
liquid-glass on
# or Super + Alt + G
```

Open the **top dashboard** and watch:

- Frosted translucent panels (not solid M3 cards)
- **Traveling specular glints** on card edges (liquid edge animation)
- Soft gel open when the dashboard appears
- Wallpaper stays **sharp** (blur only under UI layers)

If the shell does not pick up QML changes (`settings.watchFiles` may be off):

```bash
caelestia shell -k; sleep 0.5; caelestia shell -d
```

---

## 7. Features & keybinds (this rice)

| Shortcut | Action |
|----------|--------|
| `Super + /` | Keyboard shortcuts page (Nexus) |
| `Super + N` | Notification sidebar |
| `Super + Alt + T` | Toggle auto-tiling (float + size) |
| `Super + Alt + Y` | Cycle floating window size |
| `Super + Shift + M` | Minimize window |
| `Super + Alt + M` | Show minimized windows |
| `Super + Alt + V` | Video wallpaper picker |
| `Super + Alt + A` | Fancy / snappy animations |
| `Super + Alt + G` | Toggle liquid glass / solid UI |
| `Super + Alt + Escape` | Kill + restart Caelestia shell |
| `Super + Alt + U` | Unlock via shell IPC |

Launcher: type `>wallpaper` for image **and** video wallpapers.

Dashboard → **Notifications** tab = notification history UI.

### Video wallpapers

```bash
mkdir -p ~/Videos/VideoWallpapers
# drop .mp4 / .webm there
video-wallpaper   # or Super + Alt + V
```

Needs `mpvpaper` + `mpv`:

```bash
sudo dnf install -y mpv mpvpaper
```

### Liquid glass CLI

```bash
liquid-glass on
liquid-glass off
liquid-glass toggle
liquid-glass status
```

Material pieces (in the overlay):

- `LiquidGlassRect.qml` — plate, frost, top wash, depth, gel appear
- `LiquidGlassEdge.qml` — breathing radius, outer/inner rims, traveling specular, caustic beads
- Hypr layer rules blur **drawers/panels only**; `caelestia-background` / `mpvpaper` stay unblurred

---

## 8. Updating

### This rice only

```bash
cd hyprland-caelestia-fedora
git pull
./install.sh   # re-apply scripts + overlay
caelestia shell -k; sleep 0.5; caelestia shell -d
hyprctl reload
```

### Upstream Caelestia shell

```bash
cd ~/.config/quickshell/caelestia
git pull
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/ \
  -DINSTALL_QSCONFDIR="$HOME/.config/quickshell/caelestia"
cmake --build build
sudo cmake --install build
sudo chown -R "$USER:$USER" ~/.config/quickshell/caelestia

# re-apply our overlay (upstream pull overwrites custom QML)
cd /path/to/hyprland-caelestia-fedora
./install.sh
```

### Upstream CLI

```bash
cd /tmp && rm -rf caelestia-cli
git clone https://github.com/caelestia-dots/cli.git
cd cli && python3 -m build --wheel && pip install --user --force-reinstall dist/*.whl
```

---

## 9. Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Caelestia shell not found` in installer | Complete §4 first, then re-run `./install.sh` |
| Shell starts but looks stock | Overlay not applied or shell not restarted |
| Glass “on” but panels look solid/dark | Run `liquid-glass on`; check `shell.json` transparency; restart shell |
| Entire wallpaper frosted | Ensure `rules.lua` has **no blur** on `caelestia-background` / `mpvpaper` |
| Only blur, no liquid edges | Need latest overlay (`LiquidGlassEdge.qml`); restart shell hard |
| Minimize broken | Check `hypr-minimize` in PATH; rebuild minifix; start daemon if used in execs |
| Stuck lock / quote screen | `Super + Alt + U` or `Super + Alt + Escape`; rice sets `allow_session_lock_restore = false` |
| NVIDIA blur glitches | Toggle glass off, lower `blurSize` / `blurPasses` in `~/.config/hypr/variables.lua` |
| `caelestia: command not found` | Install CLI (§3) and fix `PATH` |
| Build fails on CMake/Qt | Install `qt6-qtdeclarative-devel`, `cmake`, `ninja-build` |

Debug shell:

```bash
caelestia shell -k
qs -c caelestia   # foreground logs
```

---

## 10. Repo map

```
hyprland-caelestia-fedora/
├── install.sh                 # main installer
├── README.md                  # overview
├── docs/INSTALL.md            # this guide
├── config/
│   ├── hypr/                  # Hyprland 0.56 Lua config
│   └── caelestia/             # hypr-user.lua, hypr-vars.lua, shell.json
├── scripts/
│   ├── hypr-minimize
│   ├── video-wallpaper
│   └── liquid-glass
├── minifix/hypr-minifix.c
└── shell-overlay/             # QML + service patches for Caelestia
    ├── components/effects/LiquidGlass*.qml
    ├── modules/dashboard/…    # Notifications tab, gel open, glass cards
    └── services/Colours.qml   # frost / rim helpers
```

---

## 11. Links

- This rice: https://github.com/iotserver24/hyprland-caelestia-fedora  
- Hyprland: https://hypr.land  
- COPR (this setup): https://copr.fedorainfracloud.org/coprs/sdegler/hyprland/  
- Quickshell: https://quickshell.outfoxxed.me  
- Caelestia shell: https://github.com/caelestia-dots/shell  
- Caelestia CLI: https://github.com/caelestia-dots/cli  
- Full dots (Arch-oriented): https://github.com/caelestia-dots/caelestia  

---

## License note

Configs/scripts in this repo: **MIT**.  
Caelestia remains under its upstream license — we only ship modified overlay files.
