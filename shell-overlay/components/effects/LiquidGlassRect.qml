pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.components
import qs.services
import Caelestia.Config

/**
 * Liquid Glass plate with living edges (iOS 26-inspired approximation).
 *
 * - Crystal plate + depth shadow
 * - Animated liquid rim (LiquidGlassEdge): traveling specular, gel breath, beads
 * - Gel appear: spring scale overshoot + radius settle
 */
Item {
    id: root

    property color color: Colours.palette.m3surfaceContainer
    property real radius: Tokens.rounding.extraLarge
    property real intensity: Colours.transparency.enabled ? 1 : 0
    property bool critical: false
    property bool elevated: true
    property int elevation: 3
    property real rimStrength: 0.7
    property real highlightStrength: 0.48
    // Play liquid edge animation
    property bool liquid: true
    // Gel morph on first show / when intensity turns on
    property bool gelAppear: true

    // Appear morph state
    property real gel: 1
    property real radiusMorph: 1

    readonly property real animRadius: root.radius * root.radiusMorph * (0.97 + 0.03 * gel)

    readonly property color plateColor: {
        if (root.intensity < 0.01)
            return root.color;

        const c = root.color;
        const frost = Colours.light ? 0.9 : 0.62;
        const mix = Colours.light ? 0.45 : 0.55;
        const a = Colours.transparency.enabled
            ? Math.max(0.16, Math.min(0.52, Colours.transparency.layers + 0.1))
            : 0.92;
        return Qt.rgba(
            c.r * (1 - mix) + frost * mix,
            c.g * (1 - mix) + frost * mix,
            c.b * (1 - mix) + (frost + 0.04) * mix,
            a * (0.6 + 0.4 * root.intensity)
        );
    }

    // Gel spring appear
    Component.onCompleted: {
        if (root.gelAppear && root.intensity > 0.05) {
            root.gel = 0.82;
            root.radiusMorph = 1.18;
            gelIn.start();
        }
    }

    onIntensityChanged: {
        if (root.gelAppear && root.intensity > 0.5 && root.gel > 0.95) {
            // soft re-gel when toggling glass on
            root.gel = 0.9;
            root.radiusMorph = 1.08;
            gelIn.restart();
        }
    }

    ParallelAnimation {
        id: gelIn

        SpringAnimation {
            target: root
            property: "gel"
            to: 1
            spring: 2.4
            damping: 0.22
            mass: 1.0
            epsilon: 0.005
        }
        NumberAnimation {
            target: root
            property: "radiusMorph"
            to: 1
            duration: 620
            easing.type: Easing.OutBack
            easing.overshoot: 1.6
        }
    }

    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: root.gel
        yScale: root.gel
    }

    RectangularShadow {
        visible: root.elevated && root.intensity > 0.05
        anchors.fill: plate
        radius: root.animRadius
        blur: (8 + root.elevation * 3.5) * root.intensity
        spread: -2
        offset.y: 4 + root.elevation * 0.7
        color: Qt.alpha(Colours.palette.m3shadow, 0.4 * root.intensity)
        z: -5
    }

    // Glass plate
    Rectangle {
        id: plate

        anchors.fill: parent
        radius: root.animRadius
        color: root.plateColor
        z: -4

        Behavior on color {
            CAnim {}
        }
        Behavior on radius {
            NumberAnimation {
                duration: 90
                easing.type: Easing.Linear
            }
        }
    }

    // Top light wash — pulses slightly with liquid phase from edge
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(root.animRadius * 1.9, parent.height * 0.4)
        radius: root.animRadius
        z: -3
        opacity: root.intensity * root.highlightStrength * (0.85 + 0.15 * Math.sin((edge.phase || 0) * Math.PI * 2))
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.rgba(1, 1, 1, Colours.light ? 0.58 : 0.4)
            }
            GradientStop {
                position: 0.4
                color: Qt.rgba(1, 1, 1, Colours.light ? 0.12 : 0.08)
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(1, 1, 1, 0)
            }
        }
    }

    // Bottom thickness
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height * 0.32
        radius: root.animRadius
        z: -3
        opacity: root.intensity * 0.5
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.rgba(0, 0, 0, 0)
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(0, 0, 0, Colours.light ? 0.07 : 0.24)
            }
        }
    }

    // Living liquid edge (specular travel + gel breath + beads)
    LiquidGlassEdge {
        id: edge

        anchors.fill: parent
        radius: root.animRadius
        intensity: root.liquid ? root.intensity : 0
        rimStrength: root.rimStrength
        critical: root.critical
        running: root.liquid && root.intensity > 0.05 && root.visible && root.width > 4
        z: -1
    }
}
