pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    property string source
    property alias text: label.text
    property alias radius: imgWrapper.radius
    property alias imgHeight: imgWrapper.implicitHeight
    property bool fillLabel: true
    readonly property bool isVideo: {
        const s = (source || "").toLowerCase();
        return [".mp4", ".webm", ".mkv", ".mov", ".avi", ".m4v"].some(ext => s.endsWith(ext));
    }

    signal clicked

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight

    function toUrl(path: string): string {
        if (!path)
            return "";
        if (path.startsWith("file:") || path.startsWith("http:") || path.startsWith("https:"))
            return path;
        return "file://" + path;
    }

    function loadSource(): void {
        if (!source) {
            img.source = "";
            return;
        }
        if (isVideo) {
            thumbProc.command = ["sh", "-c", `video-wallpaper thumb ${JSON.stringify(source)} 2>/dev/null`];
            thumbProc.running = true;
        } else {
            img.source = toUrl(source);
        }
    }

    onSourceChanged: loadSource()
    Component.onCompleted: loadSource()

    Process {
        id: thumbProc

        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                if (t)
                    img.source = root.toUrl(t);
            }
        }
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.small

        StyledClippingRect {
            id: imgWrapper

            Layout.fillWidth: true
            implicitHeight: width
            radius: Tokens.rounding.largeIncreased
            color: Colours.tPalette.m3surfaceContainer

            Loader {
                anchors.centerIn: parent

                opacity: img.status === Image.Ready ? 0 : 1
                active: opacity > 0

                sourceComponent: StyledRect {
                    implicitWidth: loadingIndicator.implicitSize + Tokens.padding.large * 2
                    implicitHeight: loadingIndicator.implicitSize + Tokens.padding.large * 2

                    color: Colours.palette.m3primaryContainer
                    radius: Tokens.rounding.full

                    LoadingIndicator {
                        id: loadingIndicator

                        anchors.centerIn: parent
                        containsIcon: true
                        implicitSize: Math.min(imgWrapper.width, imgWrapper.height) * 0.3
                    }

                    // Video placeholder icon when no thumb yet
                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: root.isVideo && img.status !== Image.Ready
                        text: "movie"
                        color: Colours.palette.m3onPrimaryContainer
                        fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.4).build()
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            Image {
                id: img

                anchors.fill: parent
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                sourceSize: {
                    const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
                    return Qt.size(width * dpr, height * dpr);
                }
                retainWhileLoading: true
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }

            // Video badge
            StyledRect {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.small
                visible: root.isVideo
                implicitWidth: videoBadge.implicitWidth + Tokens.padding.small * 2
                implicitHeight: videoBadge.implicitHeight + Tokens.padding.extraSmall
                radius: Tokens.rounding.full
                color: Colours.palette.m3primary

                RowLayout {
                    id: videoBadge
                    anchors.centerIn: parent
                    spacing: 2

                    MaterialIcon {
                        text: "play_arrow"
                        color: Colours.palette.m3onPrimary
                        fontStyle: Tokens.font.icon.builders.small.scale(0.9).build()
                    }

                    StyledText {
                        text: "VIDEO"
                        color: Colours.palette.m3onPrimary
                        font: Tokens.font.label.builders.small.weight(Font.Bold).build()
                    }
                }
            }
        }

        StyledText {
            id: label

            Layout.bottomMargin: Tokens.padding.small
            Layout.fillWidth: true
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.builders.small.weight(Font.Medium).build()
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }

    StateLayer {
        anchors.bottomMargin: root.fillLabel ? 0 : layout.implicitHeight - imgWrapper.implicitHeight
        onClicked: root.clicked()
    }
}
