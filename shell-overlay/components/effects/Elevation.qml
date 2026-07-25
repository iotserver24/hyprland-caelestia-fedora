import QtQuick
import QtQuick.Effects
import qs.components
import qs.services

RectangularShadow {
    property int level
    // Liquid glass: softer, wider shadows (less hard Material elevation)
    property real dp: [0, 1, 3, 6, 8, 12][level]
    property real glassBoost: Colours.transparency.enabled ? 1.35 : 1

    color: Qt.alpha(Colours.palette.m3shadow, Colours.transparency.enabled ? 0.45 : 0.7)
    blur: ((dp * 5) ** 0.7) * glassBoost
    spread: -dp * 0.3 + (dp * 0.1) ** 2
    offset.y: (dp / 2) * (Colours.transparency.enabled ? 0.85 : 1)

    Behavior on dp {
        Anim {
            type: Anim.SlowEffects
        }
    }
}
