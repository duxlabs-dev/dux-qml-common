pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell
import "IconUrl.js" as IconUrl

Singleton {
    id: root

    property var backend: null

    // False on a dux-qt-base without iconThemeRevision, whose icon provider fails on "?rev=".
    readonly property bool iconThemeLive: "iconThemeRevision" in Quickshell
    readonly property int iconThemeRevision: iconThemeLive ? Quickshell.iconThemeRevision : 0

    readonly property bool ready: backend?.ready ?? true
    readonly property url xdgCache: backend?.xdgCache ?? StandardPaths.standardLocations(StandardPaths.GenericCacheLocation)[0]
    readonly property url imagecache: backend?.imagecache ?? `${xdgCache}/imagecache`

    function stringify(path) {
        if (backend)
            return backend.stringify(path);
        const raw = path.toString();
        try {
            return decodeURIComponent(raw);
        } catch (e) {
            return raw;
        }
    }

    function strip(path) {
        if (backend)
            return backend.strip(path);
        return stringify(path).replace("file://", "");
    }

    function resolveIconPath(iconName) {
        if (backend)
            return backend.resolveIconPath(iconName);
        return themeIconUrl(iconName);
    }

    // Reads iconThemeRevision, so a binding that calls it re-runs when the icon theme changes.
    function themeIconUrl(iconName, fallbackName) {
        if (!iconName)
            return "";
        const url = (fallbackName ? Quickshell.iconPath(iconName, fallbackName) : Quickshell.iconPath(iconName, true)) || "";
        return iconThemeLive ? IconUrl.withRevision(url, iconThemeRevision) : url;
    }

    function copyPathToClipboard(path) {
        if (backend)
            backend.copyPathToClipboard(path);
    }
}
