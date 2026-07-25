pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.components
import qs.services
import Caelestia.Config

/**
 * Liquid Glass material (iOS 26-inspired approximation)
 *
 * Not flat glassmorphism: layered plate + specular rim + top light
 * + soft depth shadow. Backdrop blur comes from Hyprland layer blur.
 *
 * Drop-in style API similar to StyledRect for radius/color.
 */
Item {
    id: root

    // Base tint (scheme-driven). Glass formula derives fill/rim from this.
    property color color: Colours.palette.m3surfaceContainer
    property real radius: Tokens.rounding.extraLarge

    // 0 = solid flat, 1 = full liquid glass treatment
    property real intensity: Colours.transparency.enabled ? 1 : 0

    // Optional urgency tint (critical notifs)
    property bool critical: false
    property bool elevated: true
    property int elevation: 3

    // Specular strength
    property real rimStrength: 0.55
    property real highlightStrength: 0.42

    // Computed glass plate colour — clearer / brighter than flat M3
    readonly property color plateColor: {
        if (root.intensity < 0.01)
            return root.color;

        const c = root.color;
        const frost = Colours.light ? 0.88 : 0.58;
        const mix = Colours.light ? 0.42 : 0.52;
        const a = Colours.transparency.enabled
            ? Math.max(0.18, Math.min(0.55, Colours.transparency.layers + 0.12))
            : 0.92;
        return Qt.rgba(
            c.r * (1 - mix) + frost * mix,
            c.g * (1 - mix) + frost * mix,
            c.b * (1 - mix) + (frost + 0.03) * mix,
            a * (0.65 + 0.35 * root.intensity)
        );
    }

    readonly property color rimColor: {
        if (root.critical)
            return Qt.alpha(Colours.palette.m3error, 0.45 + 0.25 * root.intensity);
        // Bright specular rim (wet glass edge)
        return Qt.rgba(1, 1, 1, (Colours.light ? 0.55 : 0.38) * root.rimStrength * Math.max(0.35, root.intensity));
    }

    readonly property color innerRimColor: Qt.rgba(1, 1, 1, 0.12 * root.intensity)

    // Soft ambient shadow under the glass plate
    RectangularShadow {
        visible: root.elevated && root.intensity > 0.05
        anchors.fill: plate
        radius: root.radius
        blur: (6 + root.elevation * 3) * root.intensity
        spread: -2
        offset.y: 3 + root.elevation * 0.6
        color: Qt.alpha(Colours.palette.m3shadow, 0.35 * root.intensity)
        z: -4
    }

    // Main glass plate
    Rectangle {
        id: plate

        anchors.fill: parent
        radius: root.radius
        color: root.plateColor
        border.width: root.intensity > 0.05 ? 1.25 : 0
        border.color: root.rimColor
        z: -3

        Behavior on color {
            CAnim {}
        }
        Behavior on border.color {
            CAnim {}
        }
    }

    // Inner secondary rim (double-edge = thicker glass lip)
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1.25
        radius: Math.max(0, root.radius - 1.25)
        color: "transparent"
        border.width: root.intensity > 0.05 ? 1 : 0
        border.color: root.innerRimColor
        z: -2
        opacity: root.intensity
    }

    // Top specular wash — light catching the curved glass surface
    Rectangle {
        id: topHighlight

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(root.radius * 1.8, parent.height * 0.42)
        radius: root.radius
        z: -1
        opacity: root.intensity * root.highlightStrength
        // Clip bottom of gradient by matching plate radius
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.rgba(1, 1, 1, Colours.light ? 0.55 : 0.38)
            }
            GradientStop {
                position: 0.35
                color: Qt.rgba(1, 1, 1, Colours.light ? 0.14 : 0.1)
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(1, 1, 1, 0)
            }
        }
    }

    // Bottom depth — subtle darken so plate has thickness
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height * 0.35
        radius: root.radius
        z: -1
        opacity: root.intensity * 0.55
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.rgba(0, 0, 0, 0)
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(0, 0, 0, Colours.light ? 0.06 : 0.22)
            }
        }
    }

    // Side glint (left) — thin caustic-like edge light
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 1
        width: Math.max(2, root.radius * 0.35)
        radius: root.radius
        z: -1
        opacity: root.intensity * 0.35
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: Qt.rgba(1, 1, 1, 0.35)
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(1, 1, 1, 0)
            }
        }
    }
}
