pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.services
import qs.utils

Item {
    id: root

    required property ScreenState screenState
    readonly property FileDialog facePicker: FileDialog {
        title: qsTr("Select a profile picture")
        filterLabel: qsTr("Image files")
        filters: Images.validImageExtensions
        onAccepted: path => {
            if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${path}`, "Profile picture changed", `Profile picture changed to ${Paths.shortenHome(path)}`]);
            else
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "critical", "Unable to change profile picture", `Failed to change profile picture to ${Paths.shortenHome(path)}`]);
        }
    }

    readonly property real nonAnimHeight: (content.item as Content)?.nonAnimHeight ?? 0
    readonly property bool shouldBeActive: screenState.dashboard && Config.dashboard.enabled
    property real offsetScale: shouldBeActive ? 0 : 1

    // Liquid gel open: scale + slight stretch
    property real gelScale: shouldBeActive ? 1 : 0.88
    property real gelSquish: shouldBeActive ? 1 : 1.06

    visible: offsetScale < 1
    anchors.topMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 854
    opacity: 1 - offsetScale

    // Gel slide (springy, not linear)
    Behavior on offsetScale {
        NumberAnimation {
            duration: Colours.transparency.enabled ? 520 : 320
            easing.type: Colours.transparency.enabled ? Easing.OutBack : Easing.OutCubic
            easing.overshoot: 1.35
        }
    }

    Behavior on gelScale {
        SpringAnimation {
            spring: 2.6
            damping: 0.24
            mass: 1.0
            epsilon: 0.004
        }
    }

    Behavior on gelSquish {
        SpringAnimation {
            spring: 2.8
            damping: 0.26
            mass: 0.9
            epsilon: 0.004
        }
    }

    onShouldBeActiveChanged: {
        if (shouldBeActive) {
            gelScale = 0.86;
            gelSquish = 1.08;
            Qt.callLater(() => {
                gelScale = 1;
                gelSquish = 1;
            });
        }
    }

    transform: Scale {
        origin.x: root.width / 2
        origin.y: 0
        xScale: root.gelSquish
        yScale: root.gelScale
    }

    Loader {
        id: content

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
            facePicker: root.facePicker
        }
    }
}
