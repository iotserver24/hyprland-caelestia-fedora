# Hyprland + Caelestia (Fedora rice)

Personal **Hyprland 0.56 + Caelestia** customisation for **Fedora**, including **iOS-style liquid glass** UI (traveling specular edges, gel open, frost panels).

| Feature | What you get |
|--------|----------------|
| **Liquid glass UI** | Living material: specular rims, breathing radius, perimeter glints, gel springs — not flat glassmorphism |
| **Hyprland Lua config** | Animations, float mode, keybinds, layer rules (blur UI only) |
| **Caelestia shell overlay** | Notifications dashboard tab, keybind cheatsheet, video wallpapers in `>wallpaper`, notif history |
| **Minimize that works** | `hypr-minimize` + optional titlebar fix (`hypr-minifix.so`) |
| **Video wallpapers** | `video-wallpaper` via `mpvpaper` |
| **Dashboard Notifications** | 5th tab on the top dashboard |

Tested on **Fedora 44** with Hyprland from [sdegler/hyprland COPR](https://copr.fedorainfracloud.org/coprs/sdegler/hyprland/).

> Upstream shell: [caelestia-dots/shell](https://github.com/caelestia-dots/shell)  
> This repo is an **overlay + config**, not a full fork of Caelestia.

---

## Full install (recommended for friends)

**Start from a clean Fedora desktop and follow the complete guide:**

### **[docs/INSTALL.md](docs/INSTALL.md)** — Hyprland → Quickshell → Caelestia → this rice

That guide covers:

1. Fedora packages & PATH  
2. Hyprland COPR install + login session  
3. Quickshell COPR  
4. Caelestia CLI + shell (clone, cmake, smoke test)  
5. This repo’s `./install.sh` (liquid glass, minimize, video walls, …)  
6. First launch, keybinds, updates, troubleshooting  

---

## Quick install (already have Hyprland + Caelestia)

If Hyprland, Quickshell, and Caelestia shell are already working:

```bash
git clone https://github.com/iotserver24/hyprland-caelestia-fedora.git
cd hyprland-caelestia-fedora
chmod +x install.sh
./install.sh
```

Then:

```bash
hyprctl reload
caelestia shell -k; sleep 0.5; caelestia shell -d
```

---

## What the installer does

1. Checks you’re on Fedora  
2. Optionally installs recommended packages  
3. Installs helper scripts to `~/.local/bin` (`hypr-minimize`, `video-wallpaper`, `liquid-glass`)  
4. Builds `~/.local/lib/hypr-minifix.so`  
5. Copies Hyprland + Caelestia user config (with backups)  
6. Applies the **shell overlay** onto `~/.config/quickshell/caelestia`  
7. Enables **liquid glass** by default  

Backups: `~/.config/hypr.bak.<timestamp>`, per-file `*.bak.<timestamp>`, etc.

---

## Manual layout

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

## Useful keybinds

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
| `Super + Alt + G` | Toggle **liquid glass** / solid UI |
| `Super + Alt + Escape` | Restart Caelestia shell |
| `>wallpaper` | Launcher wallpaper carousel (images **+** videos) |

Open the **top dashboard** → **Notifications** tab for notification history.

---

## Liquid glass

**On by default.** Real liquid material (not plain blur/glassmorphism):

- `LiquidGlassRect` — crystalline plate, frost, top light wash, depth shadow, gel appear  
- `LiquidGlassEdge` — outer/inner rims, **traveling specular glints**, breathing radius, caustic beads  
- Hypr blur under **UI layers only** — wallpaper stays sharp  
- Dashboard open uses OutBack / spring “gel” motion  

```bash
liquid-glass on       # shell transparency + glass tokens
liquid-glass off      # solid UI
liquid-glass toggle
liquid-glass status
# or Super + Alt + G
```

If blur is heavy on weaker GPUs, turn glass off or lower `blurSize` / `blurPasses` in `~/.config/hypr/variables.lua`.

### Recent liquid-glass commits

| Commit | Change |
|--------|--------|
| `cd3bfab` | Liquid edge animation (traveling specular + gel morph) |
| `aa55453` | Liquid glass material (not glassmorphism) |
| `f15ab56` | Do not blur wallpaper layer |
| `6d19ced` | Frost lift so glass is actually visible |
| `84c3b1f` | Initial glass UI |

---

## Dependencies (Fedora)

Core:

- `hyprland` **0.56+** (Lua config) — COPR `sdegler/hyprland`  
- `quickshell` — COPR `errornointernet/quickshell`  
- Caelestia shell + `caelestia` CLI (manual / cmake + pip — see [INSTALL.md](docs/INSTALL.md))  
- `mpv` `mpvpaper` `ffmpeg` (video walls)  
- `socat` (minimize)  
- `gcc` `wayland-devel` (minifix)  
- `fuzzel` / `foot` / etc. as set in `variables.lua`  

Caelestia is **not** fully automated by this installer — install the shell first, then run the overlay.

---

## Updating

```bash
cd hyprland-caelestia-fedora
git pull
./install.sh
caelestia shell -k; sleep 0.5; caelestia shell -d
hyprctl reload
```

When upstream Caelestia updates, `git pull` their shell, rebuild if needed, then **re-run** `./install.sh` so the overlay is reapplied.

---

## Notes / laptop specifics

- Original machine: ASUS FA506NCR-class (NVIDIA + Fedora)  
- `hypr-vars.lua` disables broken suspend-then-hibernate in favour of lock  
- `allow_session_lock_restore = false` avoids stuck lock screens after crashes  
- Adjust monitors in `~/.config/caelestia/hypr-user.lua` as needed  

---

## License

Configs and scripts: **MIT** (see `LICENSE`).  
Caelestia shell remains under its own upstream license — we only ship our modified files as an overlay.

---

## Credits

- [Hyprland](https://hypr.land)  
- [Caelestia dots](https://github.com/caelestia-dots)  
- [Quickshell](https://quickshell.outfoxxed.me)  
- Community minimize / video wallpaper patterns adapted for Hyprland 0.56 Lua  
