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
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

-- XDG specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Others
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

-- NVIDIA (RTX 3050) — help Hyprland blur / GBM for liquid glass
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")

-- Make app titlebar minimize buttons work (Hyprland ignores xdg set_minimized)
-- LD_PRELOAD intercepts the Wayland request and runs hypr-minimize
hl.env("HYPR_MINIMIZE_BIN", "/home/r3ap3reditz/.local/bin/hypr-minimize")
local minifix = "/home/r3ap3reditz/.local/lib/hypr-minifix.so"
local existing = os.getenv("LD_PRELOAD")
if existing and existing ~= "" and not existing:find("hypr-minifix", 1, true) then
    hl.env("LD_PRELOAD", minifix .. ":" .. existing)
else
    hl.env("LD_PRELOAD", minifix)
end
