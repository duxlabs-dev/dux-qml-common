pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

// One JSON file written atomically, debounced by a single-shot timer that each change re-arms.
// An empty path neither reads nor writes.
QtObject {
    id: root

    property string path: ""
    property string name: "store"
    property int interval: 400
    property bool watchChanges: false
    property var serialize: null
    property var parse: null
    property alias adapter: file.adapter
    property bool loaded: false
    property bool _selfWrite: false

    signal written

    function save() {
        if (!loaded || path === "")
            return;
        _debounce.restart();
    }

    // Holds the write until the app's directories exist (Paths.ready).
    function write() {
        if (!Paths.ready) {
            _debounce.restart();
            return;
        }
        _commit();
    }

    // Writes a pending change now: the process may exit before the debounce fires.
    function flush() {
        if (!_debounce.running)
            return;
        _debounce.stop();
        file.blockWrites = true;
        _commit();
        file.blockWrites = false;
    }

    function read() {
        return file.text() ?? "";
    }

    function objectFrom(text) {
        if (text === "")
            return null;
        try {
            const data = JSON.parse(text);
            if (data && typeof data === "object" && !Array.isArray(data))
                return data;
        } catch (e) {
            Log.scoped(name).warn(`ignoring unreadable ${name}: ${e}`);
        }
        return null;
    }

    function _commit() {
        if (path === "")
            return;
        _selfWrite = watchChanges;
        if (serialize)
            file.setText(serialize());
        else
            file.writeAdapter();
        written();
    }

    readonly property Timer _debounce: Timer {
        interval: root.interval
        onTriggered: root.write()
    }

    readonly property FileView _file: FileView {
        id: file

        path: root.path
        blockLoading: true
        atomicWrites: true
        watchChanges: root.watchChanges
        printErrors: false

        onLoaded: {
            root.parse?.(text() ?? "");
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
        onFileChanged: {
            if (root._selfWrite) {
                root._selfWrite = false;
                return;
            }
            reload();
        }
        onAdapterUpdated: root.save()
    }
}
