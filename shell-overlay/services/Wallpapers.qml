pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property bool pendingPreviewClear

    readonly property list<string> videoExts: ["mp4", "webm", "mkv", "mov", "avi", "m4v"]
    readonly property string videoThumbDir: `${Paths.cache}/video-thumbs`
    // Merged stills + videos for launcher (>wallpaper) and Nexus
    property list<var> combinedList: []
    readonly property string binDir: `${Paths.home}/.local/bin`
    readonly property string videoWallBin: `${binDir}/video-wallpaper`
    readonly property string caelestiaBin: `${binDir}/caelestia`

    function getCategoryFor(w: FileSystemEntry): string {
        const path = w.path || "";
        // Videos live under ~/Videos/VideoWallpapers/<category>/...
        if (path.startsWith(Paths.videowallsdir + "/") || path.startsWith(Paths.videowallsdir)) {
            let category = w.parentDir.slice(Paths.videowallsdir.length + 1);
            if (!category)
                return "Videos";
            if (category.includes("/"))
                category = category.slice(0, category.indexOf("/"));
            return category || "Videos";
        }
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function isVideo(path: string): bool {
        const p = (path || "").toLowerCase();
        return videoExts.some(ext => p.endsWith(`.${ext}`));
    }

    function rebuildCombinedList(): void {
        const out = [];
        const seen = {};
        for (const e of stillWallpapers.entries) {
            if (e?.path && !seen[e.path]) {
                seen[e.path] = true;
                out.push(e);
            }
        }
        for (const e of videoWallpapers.entries) {
            if (e?.path && !seen[e.path]) {
                seen[e.path] = true;
                out.push(e);
            }
        }
        combinedList = out;
    }

    function setRandom(): void {
        // Prefer still images for random — video walls are intentional
        Quickshell.execDetached(["sh", "-c", `export PATH="${root.binDir}:$PATH"; ${JSON.stringify(root.videoWallBin)} stop --no-restore 2>/dev/null; ${JSON.stringify(root.caelestiaBin)} wallpaper -r ${smartArg.map(a => JSON.stringify(a)).join(" ")}`]);
    }

    function persistCurrentPath(path: string): void {
        // Keep path.txt in sync so FileView reload does not snap actualCurrent back
        Quickshell.execDetached(["sh", "-c", `mkdir -p "$(dirname -- ${JSON.stringify(root.currentNamePath)})" && printf '%s\\n' ${JSON.stringify(path)} > ${JSON.stringify(root.currentNamePath)}`]);
    }

    function setWallpaper(path: string): void {
        if (!path)
            return;
        actualCurrent = path;
        showPreview = false;
        previewPath = "";

        const pathQ = JSON.stringify(path);
        const vw = JSON.stringify(root.videoWallBin);
        const ca = JSON.stringify(root.caelestiaBin);
        const smart = smartArg.map(a => JSON.stringify(a)).join(" ");
        const pathExport = `export PATH=${JSON.stringify(root.binDir + ":")}"$PATH"`;

        if (isVideo(path)) {
            // Remember path for UI selection; start mpvpaper (hides still layer).
            // Do not feed video paths to `caelestia wallpaper -f` — it rejects non-images.
            persistCurrentPath(path);
            Quickshell.execDetached(["sh", "-c", `${pathExport}; ${vw} ${pathQ}`]);
            return;
        }

        // Full stop --no-restore (not stop-soft): re-enables wallpaperEnabled so stills paint.
        // stop-soft left wallpaperEnabled=false after video → "selected but blank desktop".
        // Persist image path first so any concurrent FileView reload sees a valid image.
        persistCurrentPath(path);
        Quickshell.execDetached(["sh", "-c", `${pathExport}; ${vw} stop --no-restore 2>/dev/null; ${ca} wallpaper -f ${pathQ} ${smart}`]);
    }

    function preview(path: string): void {
        if (!path || path === previewPath && showPreview)
            return;
        // Videos: use cached frame thumb only (no blocking colour extract while scrolling)
        if (isVideo(path)) {
            previewVideoProc.command = ["sh", "-c", `t=$(video-wallpaper thumb ${JSON.stringify(path)} 2>/dev/null) && echo "$t"`];
            previewVideoProc.running = true;
            return;
        }
        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
    }

    function stopPreview(): void {
        showPreview = false;
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    onPreviewColourLockChanged: {
        if (!previewColourLock && pendingPreviewClear)
            Colours.showPreview = false;
    }

    list: combinedList
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.combinedList.map(w => w.path).join("\n");
        }

        target: "wallpaper"
    }

    FileView {
        path: root.currentNamePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            let wall = text().trim();
            if (!wall) {
                wall = root.fallback;
                Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
            }
            // Ignore colour-scheme side-effects that briefly write a video thumb
            // path into path.txt — keep the real video if one is playing.
            if (wall && root.isVideo(root.actualCurrent) && !root.isVideo(wall) && wall.includes("/video-thumbs/"))
                return;
            root.actualCurrent = wall;
            root.previewColourLock = false;
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
        }
    }

    // Still images (+ any videos physically under Wallpapers, not via symlink)
    FileSystemModel {
        id: stillWallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Files
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.tif", "*.tiff", "*.svg", "*.gif", "*.mp4", "*.webm", "*.mkv", "*.mov", "*.avi", "*.m4v", "*.JPG", "*.JPEG", "*.PNG", "*.WEBP", "*.MP4", "*.WEBM", "*.MKV"]
        onEntriesChanged: root.rebuildCombinedList()
    }

    // Live video walls — separate tree (QDirIterator skips dir symlinks)
    FileSystemModel {
        id: videoWallpapers

        recursive: true
        path: Paths.videowallsdir
        filter: FileSystemModel.Files
        nameFilters: ["*.mp4", "*.webm", "*.mkv", "*.mov", "*.avi", "*.m4v", "*.MP4", "*.WEBM", "*.MKV", "*.MOV", "*.AVI", "*.M4V"]
        onEntriesChanged: root.rebuildCombinedList()
    }

    Component.onCompleted: rebuildCombinedList()

    Process {
        id: getPreviewColoursProc

        command: ["caelestia", "wallpaper", "-p", root.previewPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }

    Process {
        id: previewVideoProc

        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                if (!t)
                    return;
                root.previewPath = t;
                root.showPreview = true;
                if (Colours.scheme === "dynamic")
                    getPreviewColoursProc.running = true;
            }
        }
    }
}
