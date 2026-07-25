hl.config({
    animations = {
        enabled              = true,
        workspace_wraparound = false,
    },
})

--------------------------------------------------
-- Curves
-- Mix of Material-ish motion + soft springs
--------------------------------------------------

-- Soft entrance / overshoot-free settle
hl.curve("emphasizedDecel", {
    type   = "bezier",
    points = { { 0.05, 0.7 }, { 0.1, 1 } },
})

-- Snappy exit
hl.curve("emphasizedAccel", {
    type   = "bezier",
    points = { { 0.3, 0 }, { 0.8, 0.15 } },
})

-- General UI
hl.curve("standard", {
    type   = "bezier",
    points = { { 0.2, 0 }, { 0, 1 } },
})

hl.curve("easeOutQuint", {
    type   = "bezier",
    points = { { 0.23, 1 }, { 0.32, 1 } },
})

hl.curve("easeInOutCubic", {
    type   = "bezier",
    points = { { 0.65, 0.05 }, { 0.36, 1 } },
})

hl.curve("almostLinear", {
    type   = "bezier",
    points = { { 0.5, 0.5 }, { 0.75, 1 } },
})

hl.curve("quick", {
    type   = "bezier",
    points = { { 0.15, 0 }, { 0.1, 1 } },
})

hl.curve("linear", {
    type   = "bezier",
    points = { { 0, 0 }, { 1, 1 } },
})

-- Special workspace vertical slide
hl.curve("specialWorkSwitch", {
    type   = "bezier",
    points = { { 0.05, 0.7 }, { 0.1, 1 } },
})

-- Soft spring (window open / move)
hl.curve("easy", {
    type      = "spring",
    mass      = 1,
    stiffness = 71.2633,
    dampening = 15.8273644,
})

-- Slightly bouncier spring for window moves / float resize
hl.curve("bouncy", {
    type      = "spring",
    mass      = 1,
    stiffness = 220,
    dampening = 18,
})

--------------------------------------------------
-- Window animations
--------------------------------------------------

hl.animation({ leaf = "global", enabled = true, speed = 8, bezier = "standard" })

-- Parent window tree
hl.animation({ leaf = "windows", enabled = true, speed = 4.6, spring = "easy" })

-- Open: soft pop-in from 80%
hl.animation({
    leaf    = "windowsIn",
    enabled = true,
    speed   = 4.2,
    spring  = "easy",
    style   = "popin 80%",
})

-- Close: quick shrink + fade
hl.animation({
    leaf    = "windowsOut",
    enabled = true,
    speed   = 3.2,
    bezier  = "emphasizedAccel",
    style   = "popin 85%",
})

-- Move / tile / float resize — springy and smooth
hl.animation({
    leaf    = "windowsMove",
    enabled = true,
    speed   = 4.8,
    spring  = "bouncy",
})

--------------------------------------------------
-- Fade family
--------------------------------------------------

hl.animation({ leaf = "fade", enabled = true, speed = 4.5, bezier = "quick" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3.8, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.8, bezier = "almostLinear" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 5, bezier = "standard" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 4, bezier = "standard" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 4, bezier = "standard" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 4.5, bezier = "standard" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 3.6, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2.6, bezier = "almostLinear" })

--------------------------------------------------
-- Layers (launcher, OSD, overlays)
--------------------------------------------------

hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "easeOutQuint" })

hl.animation({
    leaf    = "layersIn",
    enabled = true,
    speed   = 4.2,
    bezier  = "emphasizedDecel",
    style   = "popin 90%",
})

hl.animation({
    leaf    = "layersOut",
    enabled = true,
    speed   = 3.4,
    bezier  = "emphasizedAccel",
    style   = "popin 92%",
})

--------------------------------------------------
-- Workspaces
--------------------------------------------------

-- Horizontal slide + light fade between workspaces
hl.animation({
    leaf    = "workspaces",
    enabled = true,
    speed   = 4.5,
    bezier  = "easeOutQuint",
    style   = "slidefade 12%",
})

hl.animation({
    leaf    = "workspacesIn",
    enabled = true,
    speed   = 4.2,
    bezier  = "emphasizedDecel",
    style   = "slidefade 12%",
})

hl.animation({
    leaf    = "workspacesOut",
    enabled = true,
    speed   = 4.0,
    bezier  = "emphasizedAccel",
    style   = "slidefade 12%",
})

-- Special (scratchpad) slides up
hl.animation({
    leaf    = "specialWorkspace",
    enabled = true,
    speed   = 4.2,
    bezier  = "specialWorkSwitch",
    style   = "slidefadevert 18%",
})

hl.animation({
    leaf    = "specialWorkspaceIn",
    enabled = true,
    speed   = 4.0,
    bezier  = "emphasizedDecel",
    style   = "slidefadevert 18%",
})

hl.animation({
    leaf    = "specialWorkspaceOut",
    enabled = true,
    speed   = 3.6,
    bezier  = "emphasizedAccel",
    style   = "slidefadevert 18%",
})

--------------------------------------------------
-- Border / misc
--------------------------------------------------

hl.animation({ leaf = "border", enabled = true, speed = 5.5, bezier = "easeOutQuint" })
-- borderangle looks cool but costs GPU; leave off
hl.animation({ leaf = "borderangle", enabled = false })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 6, bezier = "quick" })
