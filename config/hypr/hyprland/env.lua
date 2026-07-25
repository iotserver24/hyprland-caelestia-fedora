local vars = require("variables")

-- Themes
hl.env("QT_QPA_PLATFORMTHEME", "qtengine")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("XCURSOR_THEME", vars.cursorTheme)
hl.env("XCURSOR_SIZE", vars.cursorSize)

-- Toolkit backends
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland,x11,windows")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- XDG specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Others
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

-- Make app titlebar minimize buttons work (Hyprland ignores xdg set_minimized)
-- LD_PRELOAD intercepts the Wayland request and runs hypr-minimize
hl.env("HYPR_MINIMIZE_BIN", os.getenv("HOME") .. "/.local/bin/hypr-minimize")
local minifix = os.getenv("HOME") .. "/.local/lib/hypr-minifix.so"
local existing = os.getenv("LD_PRELOAD")
if existing and existing ~= "" and not existing:find("hypr-minifix", 1, true) then
    hl.env("LD_PRELOAD", minifix .. ":" .. existing)
else
    hl.env("LD_PRELOAD", minifix)
end
