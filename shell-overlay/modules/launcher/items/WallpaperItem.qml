import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.effects
import qs.components.images
import qs.services

Item {
    id: root

    required property FileSystemEntry modelData
    required property ScreenState screenState
    readonly property bool isVideo: Wallpapers.isVideo(modelData.path)
    property string thumbPath

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0 // qmllint disable missing-property

    Component.onCompleted: {
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0);
        opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
        if (isVideo) {
            thumbGen.command = ["sh", "-c", `video-wallpaper thumb ${JSON.stringify(modelData.path)} 2>/dev/null`];
            thumbGen.running = true;
        }
    }

    Process {
        id: thumbGen
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                if (t)
                    root.thumbPath = t;
            }
        }
    }

    implicitWidth: image.width + Tokens.padding.medium * 2
    implicitHeight: image.height + label.height + Tokens.spacing.extraSmall + Tokens.padding.large + Tokens.padding.medium

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: {
            Wallpapers.setWallpaper(root.modelData.path);
            root.screenState.launcher = false;
        }
    }

    Elevation {
        anchors.fill: image
        radius: image.radius
        opacity: root.PathView.isCurrentItem ? 1 : 0
        level: 4

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    StyledClippingRect {
        id: image

        anchors.horizontalCenter: parent.horizontalCenter
        y: Tokens.padding.large
        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.large

        implicitWidth: Tokens.sizes.launcher.wallpaperWidth
        implicitHeight: implicitWidth / 16 * 9

        MaterialIcon {
            anchors.centerIn: parent
            text: root.isVideo ? "movie" : "image"
            color: Colours.tPalette.m3outline
            fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.DemiBold).build()
            visible: root.isVideo ? !root.thumbPath : true
            z: 0
        }

        CachingImage {
            anchors.fill: parent
            path: root.thumbPath || (root.isVideo ? "" : root.modelData.path)
            smooth: !root.PathView.view.moving
            sourceSize: {
                const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
                return Qt.size(image.implicitWidth * dpr, image.implicitHeight * dpr);
            }
            z: 1
        }

        // VIDEO badge in launcher carousel
        StyledRect {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.small
            visible: root.isVideo
            implicitWidth: vlab.implicitWidth + Tokens.padding.small * 2
            implicitHeight: vlab.implicitHeight + 4
            radius: Tokens.rounding.full
            color: Colours.palette.m3primary

            StyledText {
                id: vlab
                anchors.centerIn: parent
                text: "VIDEO"
                color: Colours.palette.m3onPrimary
                font: Tokens.font.label.builders.small.weight(Font.Bold).build()
            }
        }
    }

    StyledText {
        id: label

        anchors.top: image.bottom
        anchors.topMargin: Tokens.spacing.extraSmall
        anchors.horizontalCenter: parent.horizontalCenter

        width: image.width - Tokens.padding.medium * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        renderType: Text.QtRendering
        text: root.modelData.relativePath
        font: Tokens.font.label.medium
    }

    Behavior on scale {
        Anim {}
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
