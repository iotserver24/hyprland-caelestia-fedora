#!/usr/bin/env bash
# Install Hyprland + Caelestia customisation (Fedora-oriented)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME="${HOME:-$(getent passwd "$(id -un)" | cut -d: -f6)}"
TS="$(date +%Y%m%d%H%M%S)"
DRY=0
YES=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    -y|--yes) YES=1 ;;
    -h|--help)
      echo "Usage: ./install.sh [--yes] [--dry-run]"
      exit 0
      ;;
  esac
done

c_info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
c_ok()    { printf '\033[1;32m✔\033[0m %s\n' "$*"; }
c_warn()  { printf '\033[1;33m!\033[0m %s\n' "$*"; }
c_err()   { printf '\033[1;31m✖\033[0m %s\n' "$*" >&2; }

confirm() {
  if [[ "$YES" == 1 ]]; then return 0; fi
  read -r -p "$1 [y/N] " a
  [[ "$a" == "y" || "$a" == "Y" ]]
}

backup_path() {
  local p="$1"
  if [[ -e "$p" ]]; then
    local b="${p}.bak.${TS}"
    c_info "Backup $p → $b"
    if [[ "$DRY" == 0 ]]; then cp -a "$p" "$b"; fi
  fi
}

run() {
  if [[ "$DRY" == 1 ]]; then
    echo "DRY: $*"
  else
    "$@"
  fi
}

# ── OS check ─────────────────────────────────────────────
if [[ -f /etc/os-release ]]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  c_info "Detected: ${NAME:-unknown} ${VERSION_ID:-}"
  if [[ "${ID:-}" != "fedora" && "${ID_LIKE:-}" != *fedora* ]]; then
    c_warn "This rice is aimed at Fedora. Continue anyway if you know what you're doing."
    confirm "Continue?" || exit 1
  fi
fi

# ── Packages (optional) ──────────────────────────────────
if command -v dnf >/dev/null 2>&1; then
  if confirm "Install / update recommended Fedora packages via dnf (needs sudo)?"; then
    PKGS=(
      hyprland mpv mpvpaper ffmpeg socat fuzzel foot
      gcc wayland-devel wayland-protocols-devel
      wl-clipboard cliphist grim slurp
      playerctl pavucontrol
    )
    c_info "Installing: ${PKGS[*]}"
    if [[ "$DRY" == 0 ]]; then
      sudo dnf install -y "${PKGS[@]}" || c_warn "Some packages failed — install Hyprland/Caelestia manually if needed."
    fi
  fi
else
  c_warn "dnf not found — skip package install."
fi

# ── Scripts ──────────────────────────────────────────────
c_info "Installing scripts → ~/.local/bin"
run mkdir -p "$HOME/.local/bin" "$HOME/.local/lib"
for s in hypr-minimize video-wallpaper; do
  run install -m 755 "$ROOT/scripts/$s" "$HOME/.local/bin/$s"
  c_ok "$s"
done

# ── Minifix (titlebar minimize) ──────────────────────────
if command -v gcc >/dev/null 2>&1; then
  c_info "Building hypr-minifix.so"
  if [[ "$DRY" == 0 ]]; then
    if gcc -shared -fPIC -O2 -o "$HOME/.local/lib/hypr-minifix.so" \
        "$ROOT/minifix/hypr-minifix.c" -ldl -lwayland-client 2>/tmp/minifix-build.log; then
      c_ok "hypr-minifix.so"
    else
      c_warn "minifix build failed (see /tmp/minifix-build.log). Titlebar minimize may not work; Super+Shift+M still does."
    fi
  fi
else
  c_warn "gcc missing — skip minifix build"
fi

# ── Hyprland config ──────────────────────────────────────
c_info "Installing Hyprland config"
if [[ -d "$HOME/.config/hypr" ]]; then
  if confirm "Overwrite ~/.config/hypr ? (backup will be made)"; then
    backup_path "$HOME/.config/hypr"
    run mkdir -p "$HOME/.config/hypr"
    run cp -a "$ROOT/config/hypr/." "$HOME/.config/hypr/"
    c_ok "hypr config"
  else
    c_warn "Skipped hypr config"
  fi
else
  run mkdir -p "$HOME/.config/hypr"
  run cp -a "$ROOT/config/hypr/." "$HOME/.config/hypr/"
  c_ok "hypr config (new)"
fi

# ── Caelestia user config ────────────────────────────────
c_info "Installing Caelestia user config"
run mkdir -p "$HOME/.config/caelestia"
if [[ -f "$HOME/.config/caelestia/hypr-user.lua" ]]; then
  if confirm "Overwrite ~/.config/caelestia/{hypr-user.lua,hypr-vars.lua,shell.json} ?"; then
    for f in hypr-user.lua hypr-vars.lua shell.json; do
      [[ -f "$HOME/.config/caelestia/$f" ]] && backup_path "$HOME/.config/caelestia/$f"
      run cp "$ROOT/config/caelestia/$f" "$HOME/.config/caelestia/$f"
    done
    c_ok "caelestia user config"
  else
    c_warn "Skipped caelestia user config"
  fi
else
  run cp "$ROOT/config/caelestia/"* "$HOME/.config/caelestia/" 2>/dev/null || true
  c_ok "caelestia user config (new)"
fi

# ── Shell overlay ────────────────────────────────────────
SHELL_DIR="$HOME/.config/quickshell/caelestia"
if [[ -d "$SHELL_DIR" ]]; then
  c_info "Applying shell overlay → $SHELL_DIR"
  if confirm "Apply Caelestia shell overlay (Notifications tab, wallpaper videos, notif history, …)?"; then
    while IFS= read -r -d '' f; do
      rel="${f#"$ROOT/shell-overlay/"}"
      [[ "$rel" == "upstream.patch" ]] && continue
      dest="$SHELL_DIR/$rel"
      run mkdir -p "$(dirname "$dest")"
      if [[ -f "$dest" ]]; then
        # only backup once per file type tree lightly
        [[ ! -f "${dest}.bak.${TS}" ]] && run cp -a "$dest" "${dest}.bak.${TS}" || true
      fi
      run cp "$f" "$dest"
    done < <(find "$ROOT/shell-overlay" -type f -print0)
    c_ok "shell overlay applied"
  else
    c_warn "Skipped shell overlay"
  fi
else
  c_warn "Caelestia shell not found at $SHELL_DIR"
  c_warn "Install Caelestia shell first, then re-run: ./install.sh"
fi

# ── PATH hint ────────────────────────────────────────────
if ! echo ":$PATH:" | grep -q ":$HOME/.local/bin:"; then
  c_warn 'Add ~/.local/bin to PATH, e.g. in ~/.bashrc:'
  echo '  export PATH="$HOME/.local/bin:$PATH"'
fi

echo
c_ok "Done."
echo
echo "Next:"
echo "  1. Log out → start Hyprland (or: hyprctl reload)"
echo "  2. caelestia shell -k; sleep 0.5; caelestia shell -d"
echo "  3. Super + /  → shortcuts ·  dashboard top → Notifications tab"
echo "  4. Put videos in ~/Videos/VideoWallpapers  (mp4/webm)"
echo
echo "Docs: README.md"
