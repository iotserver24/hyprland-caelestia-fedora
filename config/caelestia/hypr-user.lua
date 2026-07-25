-- User overrides for FA506NCR / Fedora (stuck lock / quote screen)

-- Do not re-lock after a crash (Hyprland lockdead / quote screen)
-- Animate resizes / drag so float mode feels smoother
hl.config({
    misc = {
        allow_session_lock_restore   = false,
        animate_manual_resizes       = true,
        animate_mouse_windowdragging = true,
    },
})

local CAELESTIA = os.getenv("HOME") .. "/.local/bin/caelestia"

-- Super + Alt + Escape → kill & restart shell (clears stuck lock UI)
hl.bind("SUPER + ALT + Escape", function()
    hl.dispatch(hl.dsp.exec_cmd(CAELESTIA .. " shell -k"))
    hl.dispatch(hl.dsp.exec_cmd("sleep 0.5 && " .. CAELESTIA .. " shell -d"))
end)

-- Super + Alt + U → unlock via shell IPC
hl.bind("SUPER + ALT + U", function()
    hl.dispatch(hl.dsp.exec_cmd(CAELESTIA .. " shell lock unlock"))
    hl.dispatch(hl.dsp.global("caelestia:unlock"))
end)

-- Super + / → keyboard shortcuts cheat sheet (Nexus page)
hl.bind("SUPER + slash", hl.dsp.global("caelestia:keybinds"))

--------------------------------------------------
-- Minimize (Hyprland has no real minimize — park on special:minimized)
-- Super + Shift + M  → minimize focused window
-- Super + Alt + M    → show / hide minimized windows tray
-- Super + Shift + Alt + M → restore last / focused minimized window
-- Titlebar minimize buttons also work via hypr-minimize daemon (IPC)
--------------------------------------------------
local MINIMIZE = os.getenv("HOME") .. "/.local/bin/hypr-minimize"

hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd(MINIMIZE))
hl.bind("SUPER + ALT + M", hl.dsp.exec_cmd(MINIMIZE .. " show"))
hl.bind("SUPER + SHIFT + ALT + M", hl.dsp.exec_cmd(MINIMIZE .. " restore"))

--------------------------------------------------
-- Super + Alt + A → toggle fancy vs snappy animations
--------------------------------------------------
local fancyAnims = true

local function apply_anim_profile(fancy)
    -- speed: lower = slower / more dramatic in Hyprland
    local winIn  = fancy and 4.2 or 6.5
    local winOut = fancy and 3.2 or 5.5
    local ws     = fancy and 4.5 or 7.0
    local move   = fancy and 4.8 or 7.0
    local spring = fancy and "bouncy" or "easy"

    hl.animation({ leaf = "windowsIn", enabled = true, speed = winIn, spring = "easy", style = fancy and "popin 80%" or "popin 92%" })
    hl.animation({ leaf = "windowsOut", enabled = true, speed = winOut, bezier = "emphasizedAccel", style = fancy and "popin 85%" or "popin 94%" })
    hl.animation({ leaf = "windowsMove", enabled = true, speed = move, spring = spring })
    hl.animation({ leaf = "workspaces", enabled = true, speed = ws, bezier = "easeOutQuint", style = fancy and "slidefade 12%" or "slidefade 6%" })
    hl.animation({ leaf = "layersIn", enabled = true, speed = fancy and 4.2 or 6.0, bezier = "emphasizedDecel", style = fancy and "popin 90%" or "fade" })

    hl.config({
        misc = {
            animate_manual_resizes       = fancy,
            animate_mouse_windowdragging = fancy,
        },
    })
end

hl.bind("SUPER + ALT + A", function()
    fancyAnims = not fancyAnims
    apply_anim_profile(fancyAnims)
    hl.notification.create({
        text    = fancyAnims
            and "Animations: Fancy\nPop-in, slidefade, springy moves"
            or  "Animations: Snappy\nFaster, lighter motion",
        timeout = 2200,
    })
end)


-- Video wallpaper picker (Super + Alt + V). Stop with: video-wallpaper stop
hl.bind("SUPER + ALT + V", function()
    hl.dispatch(hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/video-wallpaper pick"))
end)
hl.bind("SUPER + ALT + SHIFT + V", function()
    hl.dispatch(hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/video-wallpaper stop"))
end)

--------------------------------------------------
-- Floating / free-resize mode
--
-- Super + Alt + T  → toggle auto-tiling
--                    ON  = floating + sized windows (auto-tiling off)
--                    OFF = tiled again (auto-tiling on)
-- Super + Alt + Y  → cycle size of active window (forces float)
-- Super + Z        → drag-move  (Caelestia default)
-- Super + X        → drag-resize (Caelestia default)
-- Super + Alt + ←↑↓→ / Super + -/=  → keyboard resize
-- Super + Alt + Space → float/tile one window
--------------------------------------------------

-- Default size for free-float mode (percent of monitor)
local FLOAT_W = 60
local FLOAT_H = 70

-- Size presets for Super+Alt+Y (width%, height%)
local SIZE_PRESETS = {
    { 40, 50 },
    { 55, 65 },
    { 70, 80 },
    { 90, 90 },
}
local sizePresetIdx = 2 -- start at 55x65 after first press from float default

local floatModeRule = hl.window_rule({
    name    = "user-float-mode-all",
    match   = { class = ".*" },
    float   = true,
    size    = string.format("(monitor_w*%.2f) (monitor_h*%.2f)", FLOAT_W / 100, FLOAT_H / 100),
    center  = true,
    enabled = false,
})

local floatModeOn = false

local function monitor_size_px(mon, w_pct, h_pct)
    if not mon or type(mon.width) ~= "number" or type(mon.height) ~= "number" then
        return nil
    end
    local scale = (type(mon.scale) == "number" and mon.scale > 0) and mon.scale or 1
    return {
        x = math.floor(mon.width * (w_pct / 100) / scale),
        y = math.floor(mon.height * (h_pct / 100) / scale),
        relative = false,
    }
end

local function float_and_resize(win, w_pct, h_pct, cascade_i)
    if not win then return end
    local mon = win.monitor or hl.get_active_monitor()
    local size = monitor_size_px(mon, w_pct or FLOAT_W, h_pct or FLOAT_H)
    if not size then return end

    if not win.floating then
        hl.dispatch(hl.dsp.window.float({ action = "on", window = win }))
    end
    hl.dispatch(hl.dsp.window.resize({
        x = size.x,
        y = size.y,
        relative = false,
        window = win,
    }))
    hl.dispatch(hl.dsp.window.center({ window = win }))

    -- slight cascade so multiple windows are not perfectly stacked
    if cascade_i and cascade_i > 0 and mon then
        local step = 28 * cascade_i
        hl.dispatch(hl.dsp.window.move({
            x = step,
            y = step,
            relative = true,
            window = win,
        }))
    end
end

local function set_all_windows_floating(want_float)
    local windows = hl.get_windows() or {}
    local i = 0
    for _, win in ipairs(windows) do
        if win and win.mapped and not win.pinned then
            if want_float then
                float_and_resize(win, FLOAT_W, FLOAT_H, i)
                i = i + 1
            elseif win.floating then
                hl.dispatch(hl.dsp.window.float({ action = "off", window = win }))
            end
        end
    end
end

hl.bind("SUPER + ALT + T", function()
    floatModeOn = not floatModeOn
    floatModeRule:set_enabled(floatModeOn)
    set_all_windows_floating(floatModeOn)

    local title = floatModeOn and "Floating + resize mode" or "Tiling mode"
    local body  = floatModeOn
        and ("Auto-tiling OFF — windows float at " .. FLOAT_W .. "×" .. FLOAT_H .. "%\nSuper+Alt+Y cycles size · Super+X drag-resize")
        or  "Auto-tiling ON — new windows tile"
    hl.notification.create({
        text    = title .. "\n" .. body,
        timeout = 2800,
    })
end)

-- Cycle active window through size presets (forces float first)
hl.bind("SUPER + ALT + Y", function()
    local win = hl.get_active_window()
    if not win then return end

    sizePresetIdx = (sizePresetIdx % #SIZE_PRESETS) + 1
    local p = SIZE_PRESETS[sizePresetIdx]
    float_and_resize(win, p[1], p[2], 0)

    hl.notification.create({
        text    = string.format("Window size  %d×%d%%", p[1], p[2]),
        timeout = 1500,
    })
end)

