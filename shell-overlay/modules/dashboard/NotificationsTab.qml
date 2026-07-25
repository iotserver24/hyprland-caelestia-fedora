pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    required property ScreenState screenState

    readonly property int notifCount: Notifs.notClosed.length
    readonly property int criticalCount: Notifs.notClosed.filter(n => n && n.urgency === NotificationUrgency.Critical).length
    // ScriptModel needs a JS array, not a QQmlListReference
    readonly property var notifItems: {
        Notifs.list; // dependency
        Notifs.notClosed.length;
        const out = [];
        for (const n of Notifs.notClosed) {
            if (n && !n.closed)
                out.push(n);
        }
        return out;
    }

    implicitWidth: 840
    implicitHeight: Math.max(layout.implicitHeight, 360)

    // Dismiss popups while browsing this tab so they don't stack over the dashboard
    Component.onCompleted: {
        for (const n of Notifs.list)
            if (n)
                n.popup = false;
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        // ── Header ──────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.large
            Layout.rightMargin: Tokens.padding.large
            spacing: Tokens.spacing.medium

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                RowLayout {
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: qsTr("Notifications")
                        font: Tokens.font.body.builders.large.size(28).weight(Font.DemiBold).build()
                        color: Colours.palette.m3onSurface
                    }

                    // Count pill
                    StyledRect {
                        visible: root.notifCount > 0
                        implicitWidth: countLabel.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: countLabel.implicitHeight + Tokens.padding.extraSmall
                        radius: Tokens.rounding.full
                        color: root.criticalCount > 0 ? Colours.palette.m3error : Colours.palette.m3primary

                        StyledText {
                            id: countLabel
                            anchors.centerIn: parent
                            text: root.notifCount
                            color: root.criticalCount > 0 ? Colours.palette.m3onError : Colours.palette.m3onPrimary
                            font: Tokens.font.label.builders.medium.weight(Font.Bold).build()
                        }
                    }
                }

                StyledText {
                    text: root.notifCount === 0 ? qsTr("You're all caught up") : root.criticalCount > 0 ? qsTr("%1 critical · swipe or clear when done").arg(root.criticalCount) : qsTr("Tap a card to expand · Clear when done")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            // Clear all
            IconTextButton {
                visible: root.notifCount > 0
                icon: "clear_all"
                text: qsTr("Clear all")
                font: Tokens.font.body.medium
                isRound: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.large
                verticalPadding: Tokens.padding.small
                onClicked: clearTimer.start()
            }
        }

        // ── Stats row (matches weather/perf card language) ──
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.large
            Layout.rightMargin: Tokens.padding.large
            spacing: Tokens.spacing.medium
            visible: root.notifCount > 0

            StatChip {
                Layout.fillWidth: true
                icon: "notifications_active"
                label: qsTr("Active")
                value: root.notifCount.toString()
                accent: Colours.palette.m3primary
            }

            StatChip {
                Layout.fillWidth: true
                icon: "priority_high"
                label: qsTr("Critical")
                value: root.criticalCount.toString()
                accent: Colours.palette.m3error
            }

            StatChip {
                Layout.fillWidth: true
                icon: "apps"
                label: qsTr("Apps")
                value: {
                    const s = new Set();
                    for (const n of Notifs.notClosed)
                        if (n)
                            s.add(n.appName || "?");
                    return s.size.toString();
                }
                accent: Colours.palette.m3secondary
            }
        }

        // ── List / empty ────────────────────────────────────
        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 220
            Layout.preferredHeight: 280

            radius: Tokens.rounding.extraLarge * 2
            color: Colours.tPalette.m3surfaceContainer

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.medium
                visible: root.notifCount === 0
                opacity: root.notifCount === 0 ? 1 : 0

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "notifications_off"
                    color: Colours.palette.m3outlineVariant
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(2.2).build()
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("All clear")
                    font: Tokens.font.title.large
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("New notifications will land here")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            // Notification list
            ListView {
                id: listView

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                visible: root.notifCount > 0
                clip: true
                spacing: Tokens.spacing.small
                boundsBehavior: Flickable.StopAtBounds
                model: root.notifItems

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: listView
                }

                delegate: NotifCard {
                    required property var modelData
                    width: listView.width
                    notif: modelData
                }
            }
        }
    }

    // Clear all — batch by app like sidebar (avoids freezes on huge lists)
    Timer {
        id: clearTimer

        repeat: true
        triggeredOnStart: true
        interval: 12
        onTriggered: {
            const open = Notifs.notClosed;
            if (!open.length) {
                stop();
                return;
            }
            let n = 0;
            for (const item of open.slice(0, 25)) {
                item.close();
                n++;
            }
            if (Notifs.notClosed.length === 0)
                stop();
        }
    }

    // ── Stat chip ───────────────────────────────────────────
    component StatChip: StyledRect {
        id: chip

        property string icon
        property string label
        property string value
        property color accent: Colours.palette.m3primary

        radius: Tokens.rounding.extraLarge
        color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
        border.width: Colours.transparency.enabled ? 1 : 0
        border.color: Qt.rgba(1, 1, 1, Colours.light ? 0.22 : 0.12)
        implicitHeight: chipRow.implicitHeight + Tokens.padding.medium * 2

        RowLayout {
            id: chipRow

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            StyledRect {
                implicitWidth: 40
                implicitHeight: 40
                radius: Tokens.rounding.full
                color: Qt.alpha(chip.accent, 0.18)

                MaterialIcon {
                    anchors.centerIn: parent
                    text: chip.icon
                    color: chip.accent
                    fontStyle: Tokens.font.icon.medium
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: chip.label
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    text: chip.value
                    font: Tokens.font.title.medium
                    color: Colours.palette.m3onSurface
                }
            }
        }
    }

    // ── Notification card ───────────────────────────────────
    component NotifCard: StyledRect {
        id: card

        property var notif
        property bool expanded: false

        readonly property color urgencyColor: {
            if (!notif)
                return Colours.palette.m3outline;
            if (notif.urgency === NotificationUrgency.Critical)
                return Colours.palette.m3error;
            if (notif.urgency === NotificationUrgency.Low)
                return Colours.palette.m3outline;
            return Colours.palette.m3primary;
        }

        radius: Tokens.rounding.large
        color: notif && notif.urgency === NotificationUrgency.Critical ? Colours.palette.m3errorContainer : Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
        border.width: Colours.transparency.enabled ? 1 : 0
        border.color: notif && notif.urgency === NotificationUrgency.Critical
            ? Qt.alpha(Colours.palette.m3error, 0.4)
            : Qt.rgba(1, 1, 1, Colours.light ? 0.24 : 0.12)
        clip: true
        implicitHeight: cardCol.implicitHeight + Tokens.padding.medium * 2

        // Left urgency bar
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: Tokens.padding.small
            width: 3
            radius: Tokens.rounding.full
            color: card.urgencyColor
        }

        ColumnLayout {
            id: cardCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.medium + Tokens.spacing.small
            spacing: Tokens.spacing.extraSmall

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                // App avatar
                StyledRect {
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: 40
                    implicitHeight: 40
                    radius: Tokens.rounding.full
                    color: Qt.alpha(card.urgencyColor, 0.15)

                    Loader {
                        anchors.fill: parent
                        anchors.margins: card.notif?.image ? 0 : Tokens.padding.extraSmall
                        active: true
                        sourceComponent: (card.notif?.image) ? imgComp : iconComp
                    }

                    Component {
                        id: imgComp
                        StyledClippingRect {
                            anchors.fill: parent
                            radius: Tokens.rounding.full
                            Image {
                                anchors.fill: parent
                                source: Qt.resolvedUrl(card.notif.image)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }
                    }

                    Component {
                        id: iconComp
                        MaterialIcon {
                            anchors.centerIn: parent
                            text: Icons.getNotifIcon(card.notif?.summary ?? "", card.notif?.urgency ?? 0)
                            color: card.urgencyColor
                            fontStyle: Tokens.font.icon.medium
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        StyledText {
                            Layout.fillWidth: true
                            text: card.notif?.summary || qsTr("(no title)")
                            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                            color: card.notif?.urgency === NotificationUrgency.Critical ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurface
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        StyledText {
                            text: card.notif?.timeStr ?? ""
                            font: Tokens.font.label.small
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: !!(card.notif?.appName)
                        text: card.notif?.appName ?? ""
                        font: Tokens.font.label.small
                        color: Colours.palette.m3onSurfaceVariant
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: !!(card.notif?.body)
                        text: card.notif?.body ?? ""
                        font: Tokens.font.body.small
                        color: card.notif?.urgency === NotificationUrgency.Critical ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurfaceVariant
                        wrapMode: Text.WordWrap
                        maximumLineCount: card.expanded ? 12 : 2
                        elide: Text.ElideRight
                    }
                }

                // Dismiss
                IconButton {
                    Layout.alignment: Qt.AlignTop
                    z: 2
                    icon: "close"
                    font: Tokens.font.icon.small
                    type: IconButton.Standard
                    onClicked: card.notif?.close()
                }
            }
        }

        // Expand/collapse — below close button so dismiss still works
        StateLayer {
            z: 0
            anchors.fill: parent
            anchors.rightMargin: 48
            radius: parent.radius
            onClicked: card.expanded = !card.expanded
        }

        Behavior on implicitHeight {
            Anim {}
        }
    }
}
