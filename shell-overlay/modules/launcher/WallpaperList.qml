pragma ComponentBehavior: Bound

import "items"
import QtQuick
import Quickshell
import Caelestia.Config
import qs.components.controls
import qs.services

PathView {
    id: root

    required property SearchBar search
    required property var screenState
    required property var panels
    required property var content

    // Keep carousel on the wallpaper the user is looking at — do NOT snap back to
    // actualCurrent every time FileSystemModel rebuilds (downloads, thumbs, …).
    property string focusedPath: ""
    property string lastSearch: "\0" // force first sync
    property bool suppressPreview: false

    readonly property int itemWidth: Tokens.sizes.launcher.wallpaperWidth * 0.8 + Tokens.padding.medium * 2

    readonly property int numItems: {
        const screen = (QsWindow.window as QsWindow)?.screen;
        if (!screen)
            return 0;

        // Screen width - 4x outer rounding - 2x max side thickness (cause centered)
        const barMargins = Math.max(Config.border.thickness, panels.bar.implicitWidth);
        let outerMargins = 0;
        if (panels.popouts.hasCurrent && panels.popouts.currentCenter + panels.popouts.nonAnimHeight / 2 > screen.height - content.implicitHeight - Config.border.thickness * 2)
            outerMargins = panels.popouts.nonAnimWidth;
        if ((screenState.utilities || screenState.sidebar) && panels.utilities.implicitWidth > outerMargins)
            outerMargins = panels.utilities.implicitWidth;
        const maxWidth = screen.width - Config.border.rounding * 4 - (barMargins + outerMargins) * 2;

        if (maxWidth <= 0)
            return 0;

        const maxItemsOnScreen = Math.floor(maxWidth / itemWidth);
        const visible = Math.min(maxItemsOnScreen, Config.launcher.maxWallpapers, scriptModel.values.length);

        if (visible === 2)
            return 1;
        if (visible > 1 && visible % 2 === 0)
            return visible - 1;
        return visible;
    }

    function indexOfPath(path: string): int {
        if (!path)
            return -1;
        const vals = scriptModel.values;
        for (let i = 0; i < vals.length; i++) {
            if (vals[i]?.path === path)
                return i;
        }
        return -1;
    }

    function syncIndex(forceToCurrent: bool): void {
        // Don't fight the user while they scroll / flick
        if (root.moving || root.flicking)
            return;

        const search = scriptModel.search;
        let target = -1;

        if (search) {
            // Filtering: jump to first match only when the query string changes
            if (forceToCurrent || search !== root.lastSearch)
                target = 0;
            else
                target = root.indexOfPath(root.focusedPath);
            if (target < 0)
                target = 0;
        } else if (forceToCurrent) {
            target = root.indexOfPath(Wallpapers.actualCurrent);
            if (target < 0)
                target = 0;
        } else {
            // List rebuilt (new files etc.): stay on the item the user was viewing
            target = root.indexOfPath(root.focusedPath);
            if (target < 0)
                target = root.indexOfPath(Wallpapers.actualCurrent);
            if (target < 0)
                target = root.currentIndex >= 0 ? Math.min(root.currentIndex, Math.max(0, scriptModel.values.length - 1)) : 0;
        }

        root.lastSearch = search;
        if (target >= 0 && target !== root.currentIndex) {
            root.suppressPreview = true;
            root.currentIndex = target;
            root.suppressPreview = false;
        }
        // Remember focused path from the resolved index
        const item = root.currentItem as WallpaperItem;
        if (item?.modelData?.path)
            root.focusedPath = item.modelData.path;
    }

    model: ScriptModel {
        id: scriptModel

        // ">wallpaper", ">wallpaper list", ">wallpaper anime rain" → search terms after the action
        readonly property string search: {
            const raw = root.search.text || "";
            const prefix = GlobalConfig.launcher.actionPrefix + "wallpaper";
            let rest = raw;
            if (rest.startsWith(prefix))
                rest = rest.slice(prefix.length).trim();
            // optional "list" keyword: ">wallpaper list cyber"
            if (rest === "list" || rest.startsWith("list "))
                rest = rest === "list" ? "" : rest.slice(5).trim();
            return rest;
        }

        values: Wallpapers.query(search)
        onValuesChanged: root.syncIndex(false)
    }

    // Re-sync when the filter text changes (not on every FS refresh)
    Connections {
        target: root.search
        function onTextChanged(): void {
            // Defer so scriptModel.search has updated
            Qt.callLater(() => root.syncIndex(true));
        }
    }

    Component.onCompleted: {
        focusedPath = Wallpapers.actualCurrent;
        syncIndex(true);
    }
    Component.onDestruction: Wallpapers.stopPreview()

    onMovementEnded: {
        // After user scroll settles, lock focus to center item
        const item = currentItem as WallpaperItem;
        if (item?.modelData?.path)
            focusedPath = item.modelData.path;
    }

    onCurrentItemChanged: {
        if (suppressPreview)
            return;
        if (!currentItem)
            return;
        const path = (currentItem as WallpaperItem).modelData.path;
        if (path)
            focusedPath = path;
        // Debounce-ish: only preview when not mid-drag (preview stills only here;
        // video thumbs are heavy and were contributing to list thrash)
        if (!moving && !flicking)
            Wallpapers.preview(path);
    }

    implicitWidth: Math.min(numItems, count) * itemWidth
    pathItemCount: numItems
    cacheItemCount: 4

    snapMode: PathView.SnapToItem
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange

    delegate: WallpaperItem {
        screenState: root.screenState
    }

    path: Path {
        startY: root.height / 2

        PathAttribute {
            name: "z"
            value: 0
        }
        PathLine {
            x: root.width / 2
            relativeY: 0
        }
        PathAttribute {
            name: "z"
            value: 1
        }
        PathLine {
            x: root.width
            relativeY: 0
        }
    }
}
