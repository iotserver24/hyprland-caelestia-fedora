# Hyprland + Caelestia (Fedora rice)

Personal **Hyprland 0.56 + Caelestia** customisation for **Fedora**.

Includes:

| Feature | What you get |
|--------|----------------|
| **Liquid glass UI** | Frosted panels, soft blur, translucent windows (iOS-style glass) |
| **Hyprland Lua config** | Animations, float mode, keybinds, rules |
| **Caelestia shell overlay** | Notifications dashboard tab, keybind cheatsheet, video wallpapers in `>wallpaper`, notif history |
| **Minimize that works** | `hypr-minimize` + optional titlebar fix (`hypr-minifix.so`) |
| **Video wallpapers** | `video-wallpaper` via `mpvpaper` |
| **Dashboard Notifications** | 5th tab on the top dashboard |

Tested on **Fedora 44** with Hyprland from [sdegler/hyprland COPR](https://copr.fedorainfracloud.org/coprs/sdegler/hyprland/).

> Upstream shell: [caelestia-dots/shell](https://github.com/caelestia-dots/shell)  
> This repo is an **overlay + config**, not a full fork of Caelestia.

---

## Quick install (Fedora)

```bash
# clone
git clone https://github.com/iotserver24/hyprland-caelestia-fedora.git
cd hyprland-caelestia-fedora

# run installer (will ask before overwriting existing configs)
chmod +x install.sh
./install.sh
```

Then **log out and pick Hyprland** (or reboot), or from an existing session:

```bash
hyprctl reload
caelestia shell -k; sleep 0.5; caelestia shell -d
```

---

## What the installer does

1. Checks you’re on Fedora  
2. Enables Hyprland COPR (optional prompt) and installs packages if missing  
3. Installs helper scripts to `~/.local/bin`  
4. Builds `~/.local/lib/hypr-minifix.so` (needs `gcc` + `wayland-devel`)  
5. Copies Hyprland + Caelestia user config  
6. Applies the **shell overlay** onto `~/.config/quickshell/caelestia`  

It **backs up** existing configs to `~/.config/hypr.bak.<timestamp>` etc. when it would overwrite.

---

## Manual layout (if you prefer)

```
config/hypr/           →  ~/.config/hypr/
config/caelestia/      →  ~/.config/caelestia/
scripts/*              →  ~/.local/bin/
minifix/hypr-minifix.c →  build to ~/.local/lib/hypr-minifix.so
shell-overlay/*        →  merge into ~/.config/quickshell/caelestia/
```

Build minifix:

```bash
mkdir -p ~/.local/lib
gcc -shared -fPIC -O2 -o ~/.local/lib/hypr-minifix.so minifix/hypr-minifix.c -ldl -lwayland-client
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
| `>wallpaper` | Launcher wallpaper carousel (images **+** videos) |

Open the **top dashboard** → **Notifications** tab for notification history UI.

### Liquid glass

Real **liquid-glass material** (not flat glassmorphism):

- `LiquidGlassRect` — specular rim, top light wash, depth shadow, crystalline plate
- Applied to dashboard cards, media tab, notifications, chrome
- Hypr blur under UI only (wallpaper stays sharp)
- Toggle: `Super + Alt + G` / `liquid-glass on|off`

### Liquid glass

On by default. Frosted Caelestia panels + Hypr blur + soft window opacity.

```bash
liquid-glass on      # shell transparency + glass tokens
liquid-glass off     # solid UI
liquid-glass toggle  # flip
liquid-glass status
# or Super + Alt + G
```

If blur feels heavy on weaker GPUs, turn glass off or lower `blurSize` / `blurPasses` in `~/.config/hypr/variables.lua`.

---

## Dependencies (Fedora)

Core:

- `hyprland` (0.56+ Lua config)
- `quickshell` / Caelestia shell + `caelestia` CLI
- `mpv` `mpvpaper` (video walls)
- `ffmpeg` (video thumbnails)
- `socat` (minimize daemon)
- `gcc` `wayland-devel` (titlebar minimize preload)
- `fuzzel` or `wofi` (pickers, optional)
- `foot` / browser / etc. (as set in `variables.lua`)

Caelestia install is **not** fully automated here — install the shell the way you already do (official docs / your existing method), then run this overlay.

---

## Updating

```bash
cd hyprland-caelestia-fedora
git pull
./install.sh   # re-apply overlay + scripts
```

When upstream Caelestia updates, re-pull their shell, then re-run `./install.sh` so the overlay is reapplied.

---

## Notes / laptop specifics

- Original machine: ASUS FA506NCR-class laptop (NVIDIA + Fedora).  
- `hypr-vars.lua` disables broken suspend-then-hibernate in favour of lock.  
- `allow_session_lock_restore = false` avoids stuck lock screens after crashes.  
- Adjust monitors in `~/.config/caelestia/hypr-user.lua` or Hyprland monitor block as needed.

---

## License

Configs and scripts: **MIT** (see `LICENSE`).  
Caelestia shell remains under its own upstream license — we only ship our modified files as an overlay.

---

## Credits

- [Hyprland](https://hypr.land)  
- [Caelestia dots](https://github.com/caelestia-dots)  
- Community minimize / video wallpaper patterns adapted for Hyprland 0.56 Lua  
