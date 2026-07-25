pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Caelestia
import Caelestia.Config
import qs.components.misc
import qs.services
import qs.utils

Singleton {
    id: root

    property list<NotifData> list: []
    readonly property list<NotifData> notClosed: list.filter(n => n && !n.closed)
    readonly property list<NotifData> popups: list.filter(n => n && n.popup)
    property alias dnd: props.dnd

    property bool loaded
    // Cap saved/history notifications (newest first)
    readonly property int maxHistory: 80

    function hasFullscreen(): bool {
        for (const monitor of Hypr.monitors.values) {
            if (monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1))
                return true;
        }
        return false;
    }

    function shouldShowPopup(): bool {
        if (props.dnd || ShellState.anySidebarOpen())
            return false;
        if (GlobalConfig.notifs.fullscreen === "off" && hasFullscreen())
            return false;
        return true;
    }

    function trimHistory(): void {
        const open = list.filter(n => n && !n.closed);
        if (open.length <= maxHistory)
            return;
        // list is newest-first; drop oldest beyond the cap
        const drop = open.slice(maxHistory);
        for (const n of drop) {
            if (n && !n.closed)
                n.close();
        }
    }

    onDndChanged: {
        if (!GlobalConfig.utilities.toasts.dndChanged)
            return;

        if (dnd)
            Toaster.toast(qsTr("Do not disturb enabled"), qsTr("Popup notifications are now disabled"), "do_not_disturb_on");
        else
            Toaster.toast(qsTr("Do not disturb disabled"), qsTr("Popup notifications are now enabled"), "do_not_disturb_off");
    }

    onListChanged: {
        if (loaded)
            saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 1000
        onTriggered: {
            root.trimHistory();
            const items = root.notClosed.slice(0, root.maxHistory).map(n => ({
                        time: n.time,
                        id: n.notificationId,
                        summary: n.summary,
                        body: n.body,
                        appIcon: n.appIcon,
                        appName: n.appName,
                        image: n.image,
                        expireTimeout: n.expireTimeout,
                        urgency: n.urgency,
                        resident: n.resident,
                        hasActionIcons: n.hasActionIcons,
                        actions: (n.actions || []).map(a => ({
                                    identifier: a.identifier,
                                    text: a.text
                                }))
                    }));
            storage.setText(JSON.stringify(items));
        }
    }

    PersistentProperties {
        id: props

        property bool dnd

        reloadableId: "notifs"
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;

            const comp = notifComp.createObject(root, {
                popup: root.shouldShowPopup(),
                notification: notif
            });
            root.list = [comp, ...root.list];
        }
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.state}/notifs.json`
        onLoaded: {
            try {
                const data = JSON.parse(text() || "[]");
                // Load newest first, cap history
                const slice = Array.isArray(data) ? data.slice(0, root.maxHistory) : [];
                const created = [];
                for (const notif of slice) {
                    const properties = Object.assign({}, notif);

                    // Backwards compatibility for old notifications
                    if (properties.notificationId === undefined && properties.id !== undefined)
                        properties.notificationId = properties.id;

                    delete properties.id;
                    // Stored actions can't re-invoke after restart
                    if (properties.actions)
                        properties.actions = (properties.actions || []).map(a => ({
                                    identifier: a.identifier,
                                    text: a.text,
                                    invoke: () => {}
                                }));
                    const obj = notifComp.createObject(root, properties);
                    if (obj)
                        created.push(obj);
                }
                created.sort((a, b) => b.time - a.time);
                root.list = created;
            } catch (e) {
                console.warn("Failed to load notification history:", e);
                root.list = [];
            }
            root.loaded = true;
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.loaded = true;
                Qt.callLater(() => setText("[]"));
            }
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "clearNotifs"
        description: "Clear all notifications"
        onPressed: {
            for (const notif of root.list.slice())
                notif.close();
        }
    }

    IpcHandler {
        function clear(): void {
            for (const notif of root.list.slice())
                notif.close();
        }

        function isDndEnabled(): bool {
            return props.dnd;
        }

        function toggleDnd(): void {
            props.dnd = !props.dnd;
        }

        function enableDnd(): void {
            props.dnd = true;
        }

        function disableDnd(): void {
            props.dnd = false;
        }

        target: "notifs"
    }

    Component {
        id: notifComp

        NotifData {}
    }
}
