pragma ComponentBehavior: Bound

import QtQuick
import qs.DCommon.Common
import "NameFilter.js" as NameFilter

QtObject {
    id: root

    property var backend: Host.files
    property string path: ""
    property bool includeHidden: false
    property var filters: []
    property string sortKey: "name"
    property bool sortDesc: false
    property bool dirsFirst: true
    property bool hiddenLast: true
    property int pageSize: 500
    property string thumbnailSize: "normal"
    property string nameFilter: ""
    property bool thumbnailsEnabled: true
    property real thumbnailSizeLimit: -1
    property bool networkThumbnails: true

    property bool loading: false
    property string error: ""
    property string errorCode: ""
    property int total: 0
    property int hiddenCount: 0
    property string watchId: ""
    property bool watching: false
    property bool pollOnFocus: false
    property string cursor: ""

    readonly property bool available: backend?.connected === true
    readonly property ListModel entries: ListModel {}
    readonly property int count: entries.count
    readonly property bool hasMore: cursor !== ""

    property var _all: []
    property int _seq: 0
    property int _firstVisible: -1
    property int _lastVisible: -1
    property string _loadedPath: ""
    property var _requested: null
    property bool _awaiting: false
    property var _buffered: []
    property var _watchToken: null
    property var _pageToken: null
    property string _matcherQuery: ""
    property var _matcher: null
    property int _resumeAt: 0

    signal gone
    signal listed
    signal entriesAdded
    signal entriesRemoved
    signal pathReset

    readonly property ThumbnailRequests _thumbnails: ThumbnailRequests {
        backend: root.backend
        size: root.thumbnailSize
        sizeLimit: root.thumbnailSizeLimit
    }

    readonly property Connections _backendLink: Connections {
        target: root.backend
        ignoreUnknownSignals: true

        function onConnectedChanged() {
            root.reload();
        }

        function onWatchEvent(data) {
            root._onEvent(data);
        }
    }

    onPathChanged: reload()
    onBackendChanged: reload()
    onNameFilterChanged: _refilter()
    Component.onCompleted: {
        if (_loadedPath !== path)
            reload();
    }
    Component.onDestruction: _release()

    function reload() {
        _release();
        _requested = null;
        loading = false;
        if (path !== _loadedPath) {
            _loadedPath = path;
            pathReset();
        }
        if (path === "") {
            _all = [];
            entries.clear();
            total = 0;
            hiddenCount = 0;
            return;
        }
        if (!available) {
            _fail("UNAVAILABLE", "file service unavailable");
            return;
        }

        const token = _token();
        const service = backend;
        _watchToken = token;
        _requested = _options();
        loading = true;
        _await();
        service.watch(path, _options(), result => {
            if (token.stale) {
                if (result.watchId)
                    service.unwatch(result.watchId);
                return;
            }
            loading = false;
            _awaiting = false;
            if (!_accept(result)) {
                _buffered = [];
                return;
            }

            watchId = result.watchId || "";
            watching = result.watching === true;
            pollOnFocus = result.pollOnFocus === true;
            _replace(result);
            _drain();
            listed();
        });
    }

    function loadMore() {
        if (cursor === "" || watchId === "" || loading)
            return;
        _requestPage(cursor, result => {
            if (result.error) {
                _pageFailed(result);
                return;
            }
            cursor = result.cursor || "";
            total = result.total || 0;
            hiddenCount = result.hidden || 0;
            const more = result.entries || [];
            _all = _all.concat(more);
            entries.append(more.filter(entry => _passes(entry)));
            listed();
        });
    }

    function _passes(entry) {
        if (nameFilter === "")
            return true;
        if (_matcher === null || _matcherQuery !== nameFilter) {
            _matcherQuery = nameFilter;
            _matcher = NameFilter.compile(nameFilter);
        }
        return NameFilter.entryMatches(_matcher, entry);
    }

    function _refilter() {
        entries.clear();
        entries.append(_all.filter(entry => _passes(entry)));
        if (_firstVisible >= 0)
            _thumbnailRetry.restart();
        listed();
    }

    function _eachListed(wanted, visit) {
        const filtering = nameFilter !== "";
        const count = _all.length;
        const start = filtering || _resumeAt >= count ? 0 : _resumeAt;
        let shown = 0;
        let left = wanted.size;
        for (let step = 0; step < count && left > 0; step++) {
            const raw = (start + step) % count;
            const current = _all[raw];
            const visible = !filtering || _passes(current);
            if (wanted.has(current.path)) {
                const index = filtering ? shown : raw;
                visit(raw, visible ? index : -1, wanted.get(current.path));
                left--;
                _resumeAt = raw + 1;
            }
            if (visible)
                shown++;
        }
    }

    function setSort(key, desc) {
        sortKey = key;
        sortDesc = desc === true;
        repage();
    }

    function refresh() {
        if (!pollOnFocus)
            return;
        repage();
    }

    readonly property Timer _thumbnailRetry: Timer {
        interval: Anims.durShort
        onTriggered: root._requestVisibleThumbnails()
    }

    function requestThumbnails(first, last) {
        if (first < 0 || last < first)
            return;
        _firstVisible = first;
        _lastVisible = last;
        _requestVisibleThumbnails();
    }

    function _requestVisibleThumbnails() {
        const first = _firstVisible;
        const last = _lastVisible;
        if (watchId === "" || first < 0 || last < first)
            return;
        if (!thumbnailsEnabled || (pollOnFocus && !networkThumbnails))
            return;

        const paths = [];
        for (let i = first; i <= Math.min(last, entries.count - 1); i++) {
            const entry = entries.get(i);
            if (_thumbnails.wanted(entry))
                paths.push(entry.path);
        }
        _thumbnails.request(paths, watchId, items => {
            _eachListed(new Map(items.map(item => [item.path, item.thumbnail])), (raw, shown, thumbnail) => {
                _all[raw].thumbnail = thumbnail;
                if (shown >= 0)
                    entries.setProperty(shown, "thumbnail", thumbnail);
            });
        });
    }

    function indexOfPath(target) {
        for (let i = 0; i < entries.count; i++) {
            if (entries.get(i).path === target)
                return i;
        }
        return -1;
    }

    function _options(cursorValue) {
        return {
            "includeHidden": includeHidden,
            "filters": filters ?? [],
            "sortKey": sortKey,
            "sortDesc": sortDesc,
            "dirsFirst": dirsFirst,
            "hiddenLast": hiddenLast,
            "limit": pageSize,
            "thumbnailSize": thumbnailSize,
            "cursor": cursorValue || ""
        };
    }

    function _fail(code, message) {
        error = message;
        errorCode = code;
        _all = [];
        entries.clear();
        total = 0;
        hiddenCount = 0;
    }

    function _accept(result) {
        if (!result.error) {
            error = "";
            errorCode = "";
            return true;
        }
        _fail(result.code || "", result.error);
        return false;
    }

    function _sameOptions(a, b) {
        if (!a || !b)
            return false;
        if (a.includeHidden !== b.includeHidden || a.sortKey !== b.sortKey || a.sortDesc !== b.sortDesc || a.dirsFirst !== b.dirsFirst || a.hiddenLast !== b.hiddenLast || a.limit !== b.limit)
            return false;
        return a.filters.length === b.filters.length && a.filters.every((pattern, i) => pattern === b.filters[i]);
    }

    function repageIfChanged() {
        if (_sameOptions(_options(), _requested))
            return;
        repage();
    }

    function repage() {
        _requested = _options();
        if (watchId === "") {
            reload();
            return;
        }
        _await();
        _requestPage("", result => {
            if (result.error) {
                _pageFailed(result);
                return;
            }
            _awaiting = false;
            _accept(result);
            _replace(result);
            _drain();
            listed();
        });
    }

    function _token() {
        return {
            "stale": false
        };
    }

    function _requestPage(cursorValue, apply) {
        if (_pageToken)
            _pageToken.stale = true;
        const token = _token();
        _pageToken = token;
        loading = true;
        backend.page(watchId, _options(cursorValue), result => {
            if (token.stale)
                return;
            _pageToken = null;
            loading = false;
            apply(result);
        });
    }

    function _pageFailed(result) {
        const buffered = _buffered;
        const goneNow = buffered.some(event => event.watchId === watchId && event.kind === "gone");
        _release();
        if (goneNow) {
            gone();
            return;
        }
        _accept(result);
    }

    function _replace(result) {
        _seq = result.seq || 0;
        _all = (result.entries || []).slice();
        entries.clear();
        entries.append(_all.filter(entry => _passes(entry)));
        total = result.total || 0;
        hiddenCount = result.hidden || 0;
        cursor = result.cursor || "";
        if (_firstVisible >= 0)
            _thumbnailRetry.restart();
    }

    function _await() {
        _awaiting = true;
        _buffered = [];
    }

    function _drain() {
        const buffered = _buffered;
        _buffered = [];
        for (const event of buffered) {
            if (event.watchId !== watchId || event.seq <= _seq)
                continue;
            _onEvent(event);
        }
    }

    function _onEvent(data) {
        if (_awaiting) {
            _buffered.push(data);
            return;
        }
        if (watchId === "" || data.watchId !== watchId)
            return;
        if (data.kind === "gone") {
            _release();
            gone();
            return;
        }
        if (data.seq <= _seq)
            return;
        if (data.seq !== _seq + 1) {
            repage();
            _seq = data.seq;
            return;
        }
        _seq = data.seq;

        switch (data.kind) {
        case "batch":
            _applyBatch(data);
            break;
        case "resync":
            repage();
            break;
        case "thumbnails":
            _applyChanged(data.thumbnails || []);
            break;
        }
    }

    function _applyBatch(data) {
        if (data.hidden !== undefined)
            hiddenCount = data.hidden;
        _removeNamed(data.removed || []);
        _applyChanged(data.changed || []);
        _insertAt(data.added || [], data.addedAt || []);
    }

    function _removeNamed(names) {
        if (names.length === 0)
            return;
        total = Math.max(0, total - names.length);

        const gone = new Set(names);
        const filtering = nameFilter !== "";
        const kept = [];
        const dropped = [];
        let shown = 0;
        for (const entry of _all) {
            const visible = !filtering || _passes(entry);
            if (!gone.has(entry.name))
                kept.push(entry);
            else if (visible)
                dropped.push(shown);
            if (visible)
                shown++;
        }
        if (kept.length === _all.length)
            return;
        _all = kept;

        for (let last = dropped.length - 1; last >= 0; ) {
            let first = last;
            while (first > 0 && dropped[first - 1] === dropped[first] - 1)
                first--;
            entries.remove(dropped[first], last - first + 1);
            last = first - 1;
        }
        if (dropped.length > 0)
            entriesRemoved();
    }

    function _insertAt(added, at) {
        if (added.length === 0)
            return;
        total += added.length;

        const filtering = nameFilter !== "";
        const merged = [];
        const runs = [];
        let source = 0;
        let shown = 0;
        for (let i = 0; i < added.length; i++) {
            const length = merged.length + _all.length - source;
            const index = at[i] ?? length;
            if (index < merged.length) {
                repage();
                return;
            }
            if (index > length || (index === length && hasMore))
                continue;
            while (merged.length < index) {
                const existing = _all[source++];
                merged.push(existing);
                if (!filtering || _passes(existing))
                    shown++;
            }
            merged.push(added[i]);
            if (filtering && !_passes(added[i]))
                continue;
            const run = runs[runs.length - 1];
            if (run && run.at + run.items.length === shown)
                run.items.push(added[i]);
            else
                runs.push({
                    "at": shown,
                    "items": [added[i]]
                });
            shown++;
        }
        if (merged.length === 0)
            return;
        while (source < _all.length)
            merged.push(_all[source++]);
        _all = merged;

        for (const run of runs)
            entries.insert(run.at, run.items);
        if (runs.length > 0)
            entriesAdded();
    }

    function _applyChanged(changed) {
        if (changed.length === 0)
            return;
        let awaitsThumbnail = false;
        _eachListed(new Map(changed.map(entry => [entry.path, entry])), (raw, shown, entry) => {
            _all[raw] = entry;
            if (shown >= 0)
                entries.set(shown, entry);
            awaitsThumbnail = awaitsThumbnail || _thumbnails.wanted(entry);
        });
        if (awaitsThumbnail)
            _thumbnailRetry.restart();
    }

    function _release() {
        if (_watchToken)
            _watchToken.stale = true;
        if (_pageToken)
            _pageToken.stale = true;
        _watchToken = null;
        _pageToken = null;
        _awaiting = false;
        _buffered = [];
        if (watchId !== "" && backend)
            backend.unwatch(watchId);
        _thumbnails.reset();
        watchId = "";
        watching = false;
        pollOnFocus = false;
        cursor = "";
        _seq = 0;
    }
}
