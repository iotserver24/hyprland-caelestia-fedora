local vars = require("variables")

hl.config({
    decoration = {
        rounding       = vars.windowRounding,
        rounding_power = vars.windowRoundingPower or 2,

        blur = {
            enabled           = vars.blurEnabled,
            xray              = vars.blurXray,
            special           = vars.blurSpecialWs,
            ignore_opacity    = true, -- Allows opacity blurring
            new_optimizations = true,
            popups            = vars.blurPopups,
            input_methods     = vars.blurInputMethods,
            size              = vars.blurSize,
            passes            = vars.blurPasses,
            noise             = vars.blurNoise or 0.02,
            contrast          = vars.blurContrast or 0.9,
            brightness        = vars.blurBrightness or 1.05,
            vibrancy          = vars.blurVibrancy or 0.28,
        },

        shadow = {
            enabled      = vars.shadowEnabled,
            range        = vars.shadowRange,
            render_power = vars.shadowRenderPower,
            color        = vars.shadowColour,
        },
    },
})
