pragma Singleton

import Quickshell

Singleton {
    readonly property list<string> validImageTypes: ["jpeg", "png", "webp", "tiff", "svg"]
    readonly property list<string> validImageExtensions: ["jpg", "jpeg", "png", "webp", "tif", "tiff", "svg"]
    readonly property list<string> validVideoExtensions: ["mp4", "webm", "mkv", "mov", "avi", "m4v"]
    readonly property list<string> validWallpaperExtensions: [...validImageExtensions, ...validVideoExtensions]

    function isValidImageByName(name: string): bool {
        const n = name.toLowerCase();
        return validImageExtensions.some(t => n.endsWith(`.${t}`));
    }

    function isVideoByName(name: string): bool {
        const n = name.toLowerCase();
        return validVideoExtensions.some(t => n.endsWith(`.${t}`));
    }

    function isWallpaperByName(name: string): bool {
        return isValidImageByName(name) || isVideoByName(name);
    }
}
