import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Keyboard shortcuts")

    // Sections: { header, binds: [ { keys, action } ] }
    readonly property list<var> sections: [
        {
            header: qsTr("Your custom binds"),
            binds: [
                {
                    keys: "Super + Alt + T",
                    action: qsTr("Toggle auto-tiling (float + size all windows)")
                },
                {
                    keys: "Super + Alt + Y",
                    action: qsTr("Cycle active window size (40→55→70→90%)")
                },
                {
                    keys: "Super + /",
                    action: qsTr("Open this shortcuts page")
                },
                {
                    keys: "Super + Alt + A",
                    action: qsTr("Toggle enhanced animations (snappy / fancy)")
                },
                {
                    keys: "Super + Alt + G",
                    action: qsTr("Toggle liquid glass / solid UI")
                },
                {
                    keys: "Super + Shift + M",
                    action: qsTr("Minimize focused window")
                },
                {
                    keys: "Super + Alt + M",
                    action: qsTr("Show / hide minimized windows")
                },
                {
                    keys: "Super + Shift + Alt + M",
                    action: qsTr("Restore a minimized window")
                },
                {
                    keys: "Super + Alt + V",
                    action: qsTr("Video wallpaper picker")
                },
                {
                    keys: "Super + Alt + Shift + V",
                    action: qsTr("Stop video wallpaper")
                },
                {
                    keys: "Super + Alt + Escape",
                    action: qsTr("Restart Caelestia shell")
                },
                {
                    keys: "Super + Alt + U",
                    action: qsTr("Force unlock (stuck lock screen)")
                },
            ]
        },
        {
            header: qsTr("Floating & resize"),
            binds: [
                {
                    keys: "Super + Alt + Space",
                    action: qsTr("Float / tile focused window")
                },
                {
                    keys: "Super + X",
                    action: qsTr("Drag-resize window")
                },
                {
                    keys: "Super + Z",
                    action: qsTr("Drag-move window")
                },
                {
                    keys: "Super + Alt + ←↑↓→",
                    action: qsTr("Resize with keyboard")
                },
                {
                    keys: "Super + − / =",
                    action: qsTr("Resize width (Shift = height)")
                },
                {
                    keys: "Ctrl + Super + \\",
                    action: qsTr("Center window")
                },
            ]
        },
        {
            header: qsTr("Windows"),
            binds: [
                {
                    keys: "Super + Q",
                    action: qsTr("Close window")
                },
                {
                    keys: "Super + F",
                    action: qsTr("Fullscreen")
                },
                {
                    keys: "Super + Alt + F",
                    action: qsTr("Maximized (bordered)")
                },
                {
                    keys: "Super + P",
                    action: qsTr("Pin window")
                },
                {
                    keys: "Super + ←↑↓→",
                    action: qsTr("Focus window in direction")
                },
                {
                    keys: "Super + Shift + ←↑↓→",
                    action: qsTr("Swap / move window in direction")
                },
                {
                    keys: "Super + ,",
                    action: qsTr("Toggle window group")
                },
                {
                    keys: "Super + U",
                    action: qsTr("Ungroup window")
                },
                {
                    keys: "Alt + Tab",
                    action: qsTr("Cycle window group")
                },
            ]
        },
        {
            header: qsTr("Workspaces"),
            binds: [
                {
                    keys: "Super + 1…0",
                    action: qsTr("Go to workspace")
                },
                {
                    keys: "Super + Alt + 1…0",
                    action: qsTr("Move window to workspace")
                },
                {
                    keys: "Ctrl + Super + ←/→",
                    action: qsTr("Previous / next workspace")
                },
                {
                    keys: "Super + S",
                    action: qsTr("Special workspace")
                },
                {
                    keys: "Super + M",
                    action: qsTr("Music workspace")
                },
                {
                    keys: "Super + D",
                    action: qsTr("Communication workspace")
                },
                {
                    keys: "Super + R",
                    action: qsTr("Todo workspace")
                },
                {
                    keys: "Ctrl + Shift + Esc",
                    action: qsTr("System monitor workspace")
                },
            ]
        },
        {
            header: qsTr("Apps"),
            binds: [
                {
                    keys: "Super + T",
                    action: qsTr("Terminal")
                },
                {
                    keys: "Super + W",
                    action: qsTr("Browser")
                },
                {
                    keys: "Super + C",
                    action: qsTr("Editor")
                },
                {
                    keys: "Super + E",
                    action: qsTr("File explorer")
                },
                {
                    keys: "Super (hold)",
                    action: qsTr("App launcher")
                },
            ]
        },
        {
            header: qsTr("Shell / panels"),
            binds: [
                {
                    keys: "Super + N",
                    action: qsTr("Notification panel (history stays here)")
                },
                {
                    keys: "Ctrl + Alt + C",
                    action: qsTr("Clear all notifications")
                },
                {
                    keys: "Super + K",
                    action: qsTr("Show panels")
                },
                {
                    keys: "Super + L",
                    action: qsTr("Lock")
                },
                {
                    keys: "Ctrl + Alt + Delete",
                    action: qsTr("Session menu")
                },
                {
                    keys: "Ctrl + Alt + C",
                    action: qsTr("Clear notifications")
                },
                {
                    keys: "Super + V",
                    action: qsTr("Clipboard history")
                },
                {
                    keys: "Super + .",
                    action: qsTr("Emoji picker")
                },
                {
                    keys: "Print",
                    action: qsTr("Screenshot")
                },
                {
                    keys: "Super + Shift + S",
                    action: qsTr("Screenshot (freeze)")
                },
            ]
        },
    ]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: tipCol.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: tipCol

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Tip: press Super + / anytime to open this page")
                    font: Tokens.font.body.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Also available from Nexus → Keyboard shortcuts")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }
            }
        }

        Repeater {
            model: root.sections

            ColumnLayout {
                id: section

                required property var modelData
                required property int index

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    first: section.index === 0
                    text: section.modelData.header
                }

                Repeater {
                    model: section.modelData.binds

                    InfoRow {
                        required property var modelData
                        required property int index

                        first: index === 0
                        last: index === section.modelData.binds.length - 1
                        label: modelData.action
                        value: modelData.keys
                    }
                }
            }
        }
    }
}
