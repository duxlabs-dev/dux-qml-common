pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../DCommon/FileBrowser/NaturalSort.js" as NaturalSort

Singleton {
    id: root

    readonly property string home: "/home/alice"
    readonly property bool connected: true
    readonly property var capabilities: ({
            "mkdir": true,
            "rename": true,
            "trash": true,
            "search": true
        })
    readonly property var userDirs: [
        {
            "key": "home",
            "name": "alice",
            "path": home,
            "iconName": "user-home"
        },
        {
            "key": "documents",
            "name": "Documents",
            "path": home + "/Documents",
            "iconName": "folder-documents"
        },
        {
            "key": "download",
            "name": "Downloads",
            "path": home + "/Downloads",
            "iconName": "folder-download"
        },
        {
            "key": "music",
            "name": "Music",
            "path": home + "/Music",
            "iconName": "folder-music"
        },
        {
            "key": "pictures",
            "name": "Pictures",
            "path": home + "/Pictures",
            "iconName": "folder-pictures"
        }
    ]

    property var nodes: seed()
    property var watches: ({})
    property int nextWatch: 0
    property int nextSearch: 0

    signal watchEvent(var data)
    signal searchEvent(var data)

    function seed() {
        const now = Date.now();
        const day = 86400000;
        const tree = ({});
        const add = (path, size, age) => {
            tree[path] = {
                "isDir": size < 0,
                "size": size,
                "mtimeMs": now - age * day
            };
        };
        for (const dir of ["/", "/home", home, home + "/Documents", home + "/Downloads", home + "/Music", home + "/Pictures", home + "/Pictures/Wallpapers", home + "/.config", home + "/.config/dms"])
            add(dir, -1, 3);
        add(home + "/todo.txt", 812, 0);
        add(home + "/theme.json", 2048, 1);
        add(home + "/.bashrc", 3771, 40);
        add(home + "/Documents/report.pdf", 482133, 2);
        add(home + "/Documents/notes.md", 5120, 1);
        add(home + "/Documents/budget.ods", 18432, 12);
        add(home + "/Documents/vpn-office.ovpn", 4096, 30);
        add(home + "/Downloads/setup.tar.gz", 73400320, 5);
        add(home + "/Downloads/profile.jpg", 245760, 7);
        add(home + "/Downloads/display.icc", 3144, 60);
        add(home + "/Music/song.flac", 31457280, 90);
        add(home + "/Pictures/sunrise.png", 3145728, 4);
        add(home + "/Pictures/city.jpg", 2097152, 6);
        add(home + "/Pictures/logo.webp", 9216, 8);
        add(home + "/Pictures/.draft.png", 1048576, 9);
        add(home + "/Pictures/Wallpapers/mountains.webp", 4194304, 20);
        add(home + "/Pictures/Wallpapers/ocean.jpg", 5242880, 21);
        add(home + "/.config/dms/settings.json", 16384, 1);
        return tree;
    }

    function parentOf(path) {
        const cut = path.lastIndexOf("/");
        return cut <= 0 ? "/" : path.substring(0, cut);
    }

    function nameOf(path) {
        return path === "/" ? "/" : path.substring(path.lastIndexOf("/") + 1);
    }

    function childrenOf(dir) {
        return Object.keys(nodes).filter(path => path !== "/" && parentOf(path) === dir);
    }

    function mimeFor(name, isDir) {
        if (isDir)
            return "inode/directory";
        const extension = name.includes(".") ? name.substring(name.lastIndexOf(".") + 1).toLowerCase() : "";
        switch (extension) {
        case "png":
        case "jpeg":
        case "webp":
            return "image/" + extension;
        case "jpg":
            return "image/jpeg";
        case "svg":
            return "image/svg+xml";
        case "pdf":
            return "application/pdf";
        case "json":
            return "application/json";
        case "gz":
            return "application/gzip";
        case "flac":
            return "audio/flac";
        case "md":
            return "text/markdown";
        case "txt":
        case "ovpn":
            return "text/plain";
        default:
            return "application/octet-stream";
        }
    }

    function iconFor(path, mime, isDir) {
        const dir = userDirs.find(entry => entry.path === path);
        if (dir)
            return dir.iconName;
        return isDir ? "folder" : mime.replace("/", "-");
    }

    function entryFor(path) {
        const node = nodes[path];
        const name = nameOf(path);
        const extension = !node.isDir && name.lastIndexOf(".") > 0 ? name.substring(name.lastIndexOf(".") + 1).toLowerCase() : "";
        const mime = mimeFor(name, node.isDir);
        return {
            "name": name,
            "path": path,
            "isDir": node.isDir,
            "isSymlink": false,
            "symlinkTarget": "",
            "symlinkBroken": false,
            "size": node.size,
            "mtimeMs": node.mtimeMs,
            "ctimeMs": node.mtimeMs,
            "atimeMs": node.mtimeMs,
            "mode": node.isDir ? "drwxr-xr-x" : "-rw-r--r--",
            "owner": "alice",
            "group": "alice",
            "hidden": name.startsWith("."),
            "isExecutable": false,
            "extension": extension,
            "mime": mime,
            "iconName": iconFor(path, mime, node.isDir),
            "thumbnail": "",
            "thumbnailable": false,
            "unreadable": false,
            "displayName": "",
            "untrusted": false
        };
    }

    function matches(entry, filters) {
        if (entry.isDir || !filters || filters.length === 0 || filters.includes("*") || filters.includes("*.*"))
            return true;
        const name = entry.name.toLowerCase();
        return filters.some(pattern => new RegExp("^" + pattern.toLowerCase().replace(/[.+^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*").replace(/\?/g, ".") + "$").test(name));
    }

    function compare(a, b, options) {
        if ((options.dirsFirst ?? true) && a.isDir !== b.isDir)
            return a.isDir ? -1 : 1;
        if (options.hiddenLast && a.hidden !== b.hidden)
            return a.hidden ? 1 : -1;
        let order = 0;
        switch (options.sortKey) {
        case "size":
            order = a.size - b.size;
            break;
        case "mtime":
            order = a.mtimeMs - b.mtimeMs;
            break;
        case "type":
            order = a.extension.localeCompare(b.extension);
            break;
        }
        if (order === 0)
            order = NaturalSort.key(a.name).localeCompare(NaturalSort.key(b.name));
        return options.sortDesc ? -order : order;
    }

    function view(dir, options) {
        return childrenOf(dir).map(entryFor).filter(entry => (options.includeHidden || !entry.hidden) && matches(entry, options.filters)).sort((a, b) => compare(a, b, options));
    }

    function fail(callback, code, message) {
        callback?.({
            "error": message,
            "code": code
        });
    }

    function watch(path, options, callback) {
        if (!nodes[path]?.isDir) {
            fail(callback, nodes[path] ? "ENOTDIR" : "ENOENT", "not a directory: " + path);
            return;
        }
        const id = "w" + (++nextWatch);
        const entries = view(path, options);
        const next = Object.assign({}, watches);
        next[id] = {
            "path": path,
            "options": options,
            "seq": 0
        };
        watches = next;
        callback?.({
            "path": path,
            "watchId": id,
            "topic": "files:" + id,
            "seq": 0,
            "entries": entries,
            "total": entries.length,
            "cursor": "",
            "watching": true,
            "pollOnFocus": false
        });
    }

    function unwatch(watchId) {
        const next = Object.assign({}, watches);
        delete next[watchId];
        watches = next;
    }

    function page(watchId, options, callback) {
        const state = watches[watchId];
        if (!state) {
            fail(callback, "EINVAL", "unknown watch: " + watchId);
            return;
        }
        state.options = options;
        const entries = view(state.path, options);
        callback?.({
            "path": state.path,
            "watchId": watchId,
            "seq": state.seq,
            "entries": entries,
            "total": entries.length,
            "cursor": ""
        });
    }

    function stat(path, callback) {
        if (!nodes[path]) {
            fail(callback, "ENOENT", "no such file: " + path);
            return;
        }
        callback?.({
            "entry": entryFor(path)
        });
    }

    function count(paths, includeHidden, callback) {
        const counts = ({});
        for (const path of paths)
            counts[path] = {
                "count": childrenOf(path).filter(child => includeHidden || !nameOf(child).startsWith(".")).length,
                "capped": false
            };
        callback?.({
            "counts": counts
        });
    }

    function search(rootPath, query, options, callback) {
        if (!nodes[rootPath]?.isDir) {
            fail(callback, "ENOENT", "not a directory: " + rootPath);
            return;
        }
        const id = "s" + (++nextSearch);
        const needle = (query || "").toLowerCase();
        const hits = Object.keys(nodes).filter(path => path !== rootPath && path.startsWith(rootPath + "/")).map(entryFor).filter(entry => {
            if (!options?.includeHidden && entry.path.substring(rootPath.length).split("/").some(part => part.startsWith(".")))
                return false;
            return needle === "" || entry.name.toLowerCase().includes(needle);
        });
        callback?.({
            "searchId": id,
            "topic": "search:" + id,
            "limit": 10000
        });
        Qt.callLater(() => {
            searchEvent({
                "searchId": id,
                "kind": "results",
                "entries": hits,
                "count": hits.length
            });
            searchEvent({
                "searchId": id,
                "kind": "done",
                "count": hits.length,
                "truncated": false
            });
        });
    }

    function cancelSearch(searchId) {
    }

    function thumbnails(paths, size, watchId, callback) {
        callback?.({
            "results": []
        });
    }

    function mutate(dir, change) {
        const before = ({});
        for (const id in watches) {
            if (watches[id].path === dir)
                before[id] = view(dir, watches[id].options).map(entry => entry.name);
        }
        change();
        for (const id in before) {
            const state = watches[id];
            const after = view(dir, state.options);
            const names = after.map(entry => entry.name);
            const removed = before[id].filter(name => !names.includes(name));
            const added = after.filter(entry => !before[id].includes(entry.name));
            if (removed.length === 0 && added.length === 0)
                continue;
            state.seq++;
            watchEvent({
                "watchId": id,
                "kind": "batch",
                "seq": state.seq,
                "removed": removed,
                "added": added,
                "addedAt": added.map(entry => names.indexOf(entry.name))
            });
        }
    }

    function mkdir(path, callback) {
        const parent = parentOf(path);
        if (nodes[path]) {
            fail(callback, "EEXIST", "already exists: " + path);
            return;
        }
        if (!nodes[parent]?.isDir) {
            fail(callback, "ENOENT", "no such directory: " + parent);
            return;
        }
        mutate(parent, () => {
            nodes[path] = {
                "isDir": true,
                "size": -1,
                "mtimeMs": Date.now()
            };
        });
        callback?.({
            "path": path,
            "entry": entryFor(path)
        });
    }

    function rename(path, name, callback) {
        const target = parentOf(path) === "/" ? "/" + name : parentOf(path) + "/" + name;
        if (!nodes[path]) {
            fail(callback, "ENOENT", "no such file: " + path);
            return;
        }
        if (nodes[target]) {
            fail(callback, "EEXIST", "already exists: " + target);
            return;
        }
        mutate(parentOf(path), () => {
            for (const key of Object.keys(nodes)) {
                if (key !== path && !key.startsWith(path + "/"))
                    continue;
                nodes[target + key.substring(path.length)] = nodes[key];
                delete nodes[key];
            }
        });
        callback?.({
            "path": target
        });
    }

    function trash(paths, callback) {
        const trashed = [];
        const failed = [];
        for (const path of paths) {
            if (!nodes[path]) {
                failed.push({
                    "path": path,
                    "code": "ENOENT",
                    "error": "no such file: " + path
                });
                continue;
            }
            mutate(parentOf(path), () => {
                for (const key of Object.keys(nodes)) {
                    if (key === path || key.startsWith(path + "/"))
                        delete nodes[key];
                }
            });
            trashed.push(path);
        }
        callback?.({
            "trashed": trashed,
            "failed": failed
        });
    }
}
