pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import QtCore

Singleton {
    id: root

    readonly property url home: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
    readonly property url xdgCache: StandardPaths.standardLocations(StandardPaths.GenericCacheLocation)[0]
    readonly property url cache: `${xdgCache}/dank-qml-common`
    readonly property url imagecache: `${cache}/imagecache`
    readonly property bool ready: true

    function stringify(path: url): string {
        return path.toString().replace(/%20/g, " ");
    }

    function strip(path: url): string {
        return stringify(path).replace("file://", "");
    }

    function mkdir(path: url): void {
        Quickshell.execDetached(["mkdir", "-p", strip(path)]);
    }

    function resolveIconPath(iconName: string): string {
        return "";
    }

    function copyPathToClipboard(path: string): void {
        Quickshell.clipboardText = path;
    }

    Component.onCompleted: mkdir(imagecache)
}
