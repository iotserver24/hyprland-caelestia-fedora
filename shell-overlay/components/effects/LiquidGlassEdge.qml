pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import Caelestia.Config

/**
 * Animated liquid edge layer — traveling specular, gel radius breath,
 * dual caustic glints that orbit the rounded plate.
 *
 * Sits on top of a glass plate (does not draw the fill itself).
 */
Item {
    id: root

    property real radius: Tokens.rounding.extraLarge
    property real intensity: 1
    property real rimStrength: 0.7
    property bool critical: false
    property bool running: visible && intensity > 0.05 && width > 8 && height > 8

    // 0..1 continuous phase for liquid motion
    property real phase: 0

    readonly property real liveRadius: root.radius * (1 + 0.07 * Math.sin(root.phase * Math.PI * 2) * root.intensity)

    readonly property color rimColor: root.critical
        ? Qt.alpha(Colours.palette.m3error, 0.55)
        : Qt.rgba(1, 1, 1, (Colours.light ? 0.62 : 0.48) * root.rimStrength * Math.max(0.4, root.intensity))

    // Master clock — liquid time
    NumberAnimation on phase {
        from: 0
        to: 1
        duration: 2400
        loops: Animation.Infinite
        running: root.running
        easing.type: Easing.Linear
    }

    // Outer living rim (radius breathes)
    Rectangle {
        id: outerRim

        anchors.fill: parent
        radius: root.liveRadius
        color: "transparent"
        border.width: root.intensity > 0.05 ? 2 : 0
        border.color: root.rimColor
        opacity: 0.7 + 0.3 * Math.sin(root.phase * Math.PI * 2)

        Behavior on radius {
            NumberAnimation {
                duration: 80
                easing.type: Easing.Linear
            }
        }
    }

    // Inner gel lip — counter-phase breath
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1.5
        radius: Math.max(0, root.liveRadius * (1 - 0.03 * Math.sin(root.phase * Math.PI * 2 + 1.2)) - 1.5)
        color: "transparent"
        border.width: root.intensity > 0.05 ? 1 : 0
        border.color: Qt.rgba(1, 1, 1, 0.14 * root.intensity)
        opacity: root.intensity
    }

    // Traveling primary specular glint (orbits perimeter) — deliberately bright
    Item {
        id: glintA

        readonly property var p: edgePoint(root.phase)
        width: 56
        height: 28
        z: 3
        opacity: root.intensity * 0.95
        visible: root.running
        x: p.x - width / 2
        y: p.y - height / 2

        Rectangle {
            anchors.centerIn: parent
            width: 48
            height: 14
            radius: 7
            rotation: glintA.p.tangent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(1, 1, 1, 0)
                }
                GradientStop {
                    position: 0.35
                    color: Qt.rgba(1, 1, 1, Colours.light ? 0.85 : 0.7)
                }
                GradientStop {
                    position: 0.5
                    color: Qt.rgba(1, 1, 1, 1)
                }
                GradientStop {
                    position: 0.65
                    color: Qt.rgba(1, 1, 1, Colours.light ? 0.85 : 0.7)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(1, 1, 1, 0)
                }
            }
        }

        // Soft bloom
        Rectangle {
            anchors.centerIn: parent
            width: 64
            height: 24
            radius: 12
            rotation: glintA.p.tangent
            color: Qt.rgba(1, 1, 1, 0.2 * root.intensity)
        }
    }

    // Secondary counter-orbit glint
    Item {
        id: glintB

        readonly property real t: (root.phase + 0.52) % 1
        readonly property var p: edgePoint(t)
        width: 36
        height: 20
        z: 3
        opacity: root.intensity * 0.55
        visible: root.running
        x: p.x - width / 2
        y: p.y - height / 2

        Rectangle {
            anchors.centerIn: parent
            width: 28
            height: 10
            radius: 5
            rotation: glintB.p.tangent
            color: Qt.rgba(1, 1, 1, 0.65)
        }
    }

    // Micro caustic beads chasing along edge
    Repeater {
        model: 4

        Item {
            required property int index
            readonly property real t: (root.phase + index * 0.14) % 1
            readonly property var p: edgePoint(t)

            width: 8
            height: 8
            x: p.x - 4
            y: p.y - 4
            opacity: root.intensity * (0.35 + 0.35 * Math.sin(root.phase * Math.PI * 2 + index * 1.3))
            visible: root.running
            z: 3

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Qt.rgba(1, 1, 1, 0.85)
            }
        }
    }

    /**
     * Point + tangent (degrees) on a rounded-rect perimeter.
     * t in [0,1) walks clockwise from top-left corner arc start (top edge mid-ish).
     */
    function edgePoint(t: real): var {
        const w = Math.max(1, root.width);
        const h = Math.max(1, root.height);
        const r = Math.max(1, Math.min(root.liveRadius, Math.min(w, h) / 2 - 0.5));

        const top = Math.max(0, w - 2 * r);
        const right = Math.max(0, h - 2 * r);
        const bottom = top;
        const left = right;
        const arc = Math.PI * 0.5 * r; // quarter circle length
        const peri = top + right + bottom + left + 4 * arc;
        if (peri <= 0)
            return {
                x: w / 2,
                y: 0,
                tangent: 0
            };

        let d = ((t % 1) + 1) % 1 * peri;

        // top edge L→R
        if (d < top) {
            return {
                x: r + d,
                y: 0,
                tangent: 0
            };
        }
        d -= top;

        // top-right arc
        if (d < arc) {
            const a = -Math.PI / 2 + (d / arc) * (Math.PI / 2);
            return {
                x: w - r + Math.cos(a) * r,
                y: r + Math.sin(a) * r,
                tangent: a * 180 / Math.PI + 90
            };
        }
        d -= arc;

        // right edge T→B
        if (d < right) {
            return {
                x: w,
                y: r + d,
                tangent: 90
            };
        }
        d -= right;

        // bottom-right arc
        if (d < arc) {
            const a = 0 + (d / arc) * (Math.PI / 2);
            return {
                x: w - r + Math.cos(a) * r,
                y: h - r + Math.sin(a) * r,
                tangent: a * 180 / Math.PI + 90
            };
        }
        d -= arc;

        // bottom edge R→L
        if (d < bottom) {
            return {
                x: w - r - d,
                y: h,
                tangent: 180
            };
        }
        d -= bottom;

        // bottom-left arc
        if (d < arc) {
            const a = Math.PI / 2 + (d / arc) * (Math.PI / 2);
            return {
                x: r + Math.cos(a) * r,
                y: h - r + Math.sin(a) * r,
                tangent: a * 180 / Math.PI + 90
            };
        }
        d -= arc;

        // left edge B→T
        if (d < left) {
            return {
                x: 0,
                y: h - r - d,
                tangent: 270
            };
        }
        d -= left;

        // top-left arc
        const a = Math.PI + (d / Math.max(0.001, arc)) * (Math.PI / 2);
        return {
            x: r + Math.cos(a) * r,
            y: r + Math.sin(a) * r,
            tangent: a * 180 / Math.PI + 90
        };
    }
}
