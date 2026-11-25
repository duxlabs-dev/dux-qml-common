pragma ComponentBehavior: Bound

import QtQuick
import qs.DCommon.Common
import qs.DCommon.Widgets

FocusScope {
    id: root

    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    property string mode: "open"
    property var filters: []
    property bool multiple: false
    property string defaultName: ""
    property string startPath: ""
    property string bucket: "default"
    property string title: I18n.tr("Select File", "default file browser window title")
    property bool showHeader: true
    property var windowControls: null
    property bool defaultShowHidden: false
    property string defaultViewMode: "list"
    property var backend: Host.files
    property bool autoReset: true

    property string viewMode: defaultViewMode
    property string sortKey: "name"
    property bool sortDescending: false
    property int gridZoom: FileBrowserMetrics.defaultGridZoom
    property int listZoom: FileBrowserMetrics.defaultListZoom
    property bool showSidebar: true
    property bool showHidden: defaultShowHidden

    readonly property bool saving: mode === "save"
    readonly property string currentPath: browser.path
    readonly property alias browser: browser
    property alias fileName: nameField.text
    readonly property var capabilities: backend?.capabilities ?? ({})
    readonly property bool compact: width < FileBrowserMetrics.sidebarBreakpoint
    readonly property bool sidebarDocked: showSidebar && !compact
    readonly property bool floating: Style.isFloatingWindow(root)
    readonly property color cardColor: Style.foregroundColor(Style.cardSurface, floating)
    readonly property color selectedLayer: Style.selectedColor(floating)
    readonly property var viewModes: [
        {
            "value": "grid",
            "icon": "grid_view",
            "label": I18n.tr("Grid view", "file browser toolbar button switching to the grid")
        },
        {
            "value": "list",
            "icon": "view_list",
            "label": I18n.tr("List view", "file browser toolbar button switching to the list")
        }
    ]
    readonly property string typedTarget: {
        const typed = nameField.text.trim();
        if (typed.startsWith("/") || typed.startsWith("~"))
            return FilePaths.normalize(typed);
        return typed === "" || browser.path === "" ? "" : FilePaths.join(browser.path, typed);
    }
    readonly property bool canAccept: {
        switch (mode) {
        case "save":
            return typedTarget !== "" && FileFormat.validName(FilePaths.baseName(typedTarget));
        case "openFolder":
            return browser.path !== "";
        default:
            return browser.selectedEntries.length > 0;
        }
    }
    readonly property string statusText: {
        const entries = browser.selectedEntries;
        if (entries.length !== 1)
            return browser.directory.total > 0 ? FileFormat.count(browser.directory.total) : "";
        const entry = entries[0];
        const name = FileFormat.shownName(entry.displayName ?? "", entry.name, entry.isDir ?? false);
        const detail = FileColumns.value("size", entry, -1);
        return detail === "" ? name : `${name} · ${detail}`;
    }

    property string _error: ""
    property string _overwriteTarget: ""
    property string _rememberedPath: ""
    property bool _restoring: false

    signal accepted(var paths)
    signal rejected

    function reset() {
        const saved = FileBrowserSettings.load(bucket);
        _restoring = true;
        viewMode = saved.viewMode || defaultViewMode;
        sortKey = saved.sortKey;
        sortDescending = saved.sortDesc;
        gridZoom = saved.gridZoom;
        listZoom = saved.listZoom;
        showSidebar = saved.showSidebar;
        showHidden = saved.showHidden ?? defaultShowHidden;
        _error = "";
        _overwriteTarget = "";
        _rememberedPath = "";
        nameField.text = defaultName;
        searchField.text = "";
        browser.restoreState({
            "path": ""
        });
        _restoring = false;
        _openStart(saved.lastPath);
        _focusStart();
    }

    function setViewMode(value) {
        viewMode = value;
        _persist({
            "viewMode": value
        });
    }

    function setSort(key, descending) {
        sortKey = key;
        sortDescending = descending;
        _persist({
            "sortKey": key,
            "sortDesc": descending
        });
    }

    function setZoom(forMode, level) {
        if (forMode === "grid") {
            gridZoom = level;
            _persist({
                "gridZoom": level
            });
            return;
        }
        listZoom = level;
        _persist({
            "listZoom": level
        });
    }

    function setShowSidebar(value) {
        showSidebar = value;
        _persist({
            "showSidebar": value
        });
    }

    function setShowHidden(value) {
        showHidden = value;
        _persist({
            "showHidden": value
        });
    }

    function activate(entry) {
        _error = "";
        if (entry.isDir) {
            browser.navigate(entry.path);
            return;
        }
        switch (mode) {
        case "openFolder":
            return;
        case "save":
            nameField.text = entry.name;
            _overwriteTarget = entry.path;
            return;
        default:
            _finish([entry.path]);
        }
    }

    function acceptCurrent() {
        if (!canAccept)
            return;
        _error = "";
        const selected = browser.selectedEntries;
        switch (mode) {
        case "save":
            _save(typedTarget);
            return;
        case "openFolder":
            {
                const dirs = selected.filter(entry => entry.isDir);
                _finish([dirs.length === 1 ? dirs[0].path : browser.path]);
                return;
            }
        default:
            {
                if (selected.length === 1 && selected[0].isDir) {
                    browser.navigate(selected[0].path);
                    return;
                }
                const files = selected.filter(entry => !entry.isDir).map(entry => entry.path);
                if (files.length === 0)
                    return;
                _finish(multiple ? files : [files[0]]);
            }
        }
    }

    function createFolder(name) {
        const target = FilePaths.join(browser.path, name.trim());
        newFolderDialog.opened = false;
        _focusStart();
        backend.mkdir(target, result => {
            if (result.error) {
                root._error = FileFormat.operationError(result.code, result.error);
                return;
            }
            browser.navigate(result.path || target);
        });
    }

    function renameItem(target, name) {
        backend.rename(target, name, result => {
            if (!result.error)
                return;
            root._error = FileFormat.operationError(result.code, result.error);
        });
    }

    function trashItems(paths) {
        backend.trash(paths, result => {
            const failed = result.failed ?? [];
            if (result.error || failed.length > 0)
                root._error = FileFormat.operationError(result.code ?? failed[0]?.code ?? "", result.error ?? failed[0]?.error ?? "");
        });
    }

    function focusSearch() {
        searchField.forceActiveFocus();
        searchField.cursorPosition = searchField.text.length;
    }

    function _typeIntoSearch(text) {
        searchField.text += text;
        focusSearch();
    }

    function _focusFirstMatch() {
        browser.focusBody();
        if (browser.directory.count > 0)
            browser.body.jumpTo(0, Qt.NoModifier);
    }

    function _save(target) {
        if (!backend?.connected) {
            _finish([target]);
            return;
        }
        backend.stat(target, result => {
            if (result.error) {
                if (result.code === "ENOENT") {
                    root._finish([target]);
                    return;
                }
                root._error = FileFormat.operationError(result.code, result.error);
                return;
            }
            if (result.entry?.isDir) {
                nameField.text = "";
                browser.navigate(target);
                return;
            }
            root._overwriteTarget = target;
        });
    }

    function _finish(paths) {
        _rememberPath();
        accepted(paths);
    }

    function _rememberPath() {
        if (browser.path === "" || browser.path === _rememberedPath)
            return;
        _rememberedPath = browser.path;
        _persist({
            "lastPath": browser.path
        });
    }

    function _persist(patch) {
        if (_restoring)
            return;
        FileBrowserSettings.save(bucket, patch);
    }

    function _openStart(lastPath) {
        const fallback = lastPath || browser.homePath;
        const start = FilePaths.normalize(startPath);
        if (start === "") {
            browser.navigate(fallback);
            return;
        }
        if (!backend?.connected) {
            browser.reveal(start);
            return;
        }
        backend.stat(start, result => {
            if (result.error) {
                browser.navigate(fallback);
                return;
            }
            if (result.entry?.isDir) {
                browser.navigate(start);
                return;
            }
            browser.reveal(start);
        });
    }

    function _focusStart() {
        if (saving) {
            nameField.forceActiveFocus();
            nameField.selectAll();
            return;
        }
        browser.focusBody();
    }

    Keys.onPressed: event => {
        const control = (event.modifiers & Qt.ControlModifier) !== 0;
        const alt = (event.modifiers & Qt.AltModifier) !== 0;
        switch (event.key) {
        case Qt.Key_Escape:
            if (searchField.text !== "") {
                searchField.clear();
                break;
            }
            root.rejected();
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            {
                if (!browser.body.activeFocus)
                    return;
                const entry = browser.currentEntry;
                if (entry && browser.selection.count === 1 && browser.selection.contains(entry.path)) {
                    root.activate(entry);
                    break;
                }
                root.acceptCurrent();
                break;
            }
        case Qt.Key_A:
            if (!control || !root.multiple)
                return;
            browser.selection.selectAll(browser.directory.entries);
            break;
        case Qt.Key_F:
            if (!control)
                return;
            root.focusSearch();
            break;
        case Qt.Key_L:
            if (!control)
                return;
            browser.editPath();
            break;
        case Qt.Key_H:
            if (!control)
                return;
            root.setShowHidden(!root.showHidden);
            break;
        case Qt.Key_Left:
            if (!alt)
                return;
            browser.back();
            break;
        case Qt.Key_Right:
            if (!alt)
                return;
            browser.forward();
            break;
        case Qt.Key_Up:
            if (!alt)
                return;
            browser.up();
            break;
        case Qt.Key_F2:
            {
                const entry = browser.currentEntry;
                if (!entry || root.capabilities.rename !== true)
                    return;
                browser.beginRename(entry.path);
                break;
            }
        default:
            return;
        }
        event.accepted = true;
    }

    Component.onCompleted: {
        if (autoReset)
            reset();
    }
    Component.onDestruction: _rememberPath()
    onRejected: _rememberPath()

    Connections {
        target: browser.selection
        enabled: root.saving

        function onPathsChanged() {
            const selected = browser.selectedEntries;
            if (selected.length !== 1 || selected[0].isDir)
                return;
            nameField.text = selected[0].name;
        }
    }

    component CardSegment: Rectangle {
        property bool first: false
        property bool last: false

        readonly property real topRadius: first ? FileBrowserMetrics.paneRadius : Style.groupedListInnerRadius
        readonly property real bottomRadius: last ? FileBrowserMetrics.paneRadius : Style.groupedListInnerRadius

        anchors.left: parent.left
        anchors.right: parent.right
        color: root.cardColor
        topLeftRadius: topRadius
        topRightRadius: topRadius
        bottomLeftRadius: bottomRadius
        bottomRightRadius: bottomRadius
    }

    component FlatButton: DActionButton {
        anchors.verticalCenter: parent.verticalCenter
        focusPolicy: Qt.TabFocus
        buttonSize: FileBrowserMetrics.controlSize
        iconSize: Style.iconSizeMedium
        iconColor: Style.surfaceText
    }

    DWindowHeader {
        id: header

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.showHeader
        height: !visible ? 0 : collapsed ? implicitHeight : Math.max(implicitHeight, FileBrowserMetrics.headerHeight)
        controls: root.windowControls
        title: root.title
        onCloseRequested: root.rejected()
    }

    Item {
        id: sidebarSlot

        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: root.sidebarDocked ? FileBrowserMetrics.sidebarWidth : 0
        clip: true

        Behavior on width {
            DAnim {
                duration: Style.expressiveDurations.expressiveSlowEffects
                easing.bezierCurve: Style.expressiveCurves.expressiveSlowEffects
            }
        }

        FileBrowserSidebar {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: FileBrowserMetrics.sidebarWidth
            visible: parent.width > 0
            places: root.backend?.userDirs ?? []
            currentPath: browser.path
            onPlaceSelected: target => {
                browser.focusBody();
                browser.navigate(target);
            }
        }
    }

    Item {
        id: content

        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: root.showHeader ? 0 : FileBrowserMetrics.contentMargin
        anchors.bottomMargin: FileBrowserMetrics.contentMargin
        anchors.leftMargin: Math.max(FileBrowserMetrics.contentMargin, sidebarSlot.width)
        anchors.rightMargin: FileBrowserMetrics.contentMargin

        CardSegment {
            id: topSegment

            first: true
            anchors.top: parent.top
            height: topbar.height + FileBrowserMetrics.pickerCardPadding * 2
        }

        Item {
            id: topbar

            readonly property real centerWidth: width - leftActions.width - rightActions.width - FileBrowserMetrics.controlSpacing * 2
            readonly property bool searchNarrow: centerWidth < FileBrowserMetrics.pickerSearchCollapseBelow
            readonly property bool searchTakesAll: searchNarrow && (searchField.activeFocus || searchField.text !== "")
            readonly property bool searchCollapsed: searchNarrow && !searchTakesAll

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: FileBrowserMetrics.pickerCardPadding
            height: FileBrowserMetrics.controlSize

            Row {
                id: leftActions

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.spacingXS

                FlatButton {
                    visible: !root.compact
                    iconName: "menu"
                    tooltipText: I18n.tr("Quick Access", "file browser sidebar section header")
                    onClicked: root.setShowSidebar(!root.showSidebar)
                }

                FlatButton {
                    enabled: browser.canGoBack
                    iconName: I18n.isRtl ? "arrow_forward" : "arrow_back"
                    tooltipText: I18n.tr("Back", "tooltip on the button going to the previous location")
                    onClicked: browser.back()
                }

                FlatButton {
                    enabled: browser.canGoForward
                    iconName: I18n.isRtl ? "arrow_back" : "arrow_forward"
                    tooltipText: I18n.tr("Forward", "tooltip on the button going to the next location")
                    onClicked: browser.forward()
                }

                FlatButton {
                    visible: root.capabilities.mkdir === true
                    enabled: browser.path !== ""
                    iconName: "create_new_folder"
                    tooltipText: I18n.tr("New folder", "file browser toolbar button creating a folder")
                    onClicked: newFolderDialog.show()
                }
            }

            Item {
                id: pathSlot

                anchors.left: leftActions.right
                anchors.right: searchField.visible ? searchField.left : rightActions.left
                anchors.leftMargin: FileBrowserMetrics.controlSpacing
                anchors.rightMargin: FileBrowserMetrics.controlSpacing
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                visible: !topbar.searchTakesAll
            }

            DSearchField {
                id: searchField

                anchors.right: rightActions.left
                anchors.rightMargin: FileBrowserMetrics.controlSpacing
                anchors.verticalCenter: parent.verticalCenter
                visible: !topbar.searchCollapsed
                width: topbar.searchTakesAll ? topbar.centerWidth : Math.max(FileBrowserMetrics.pickerSearchMinWidth, Math.min(FileBrowserMetrics.pickerSearchMaxWidth, topbar.centerWidth * FileBrowserMetrics.pickerSearchShare))
                fieldHeight: FileBrowserMetrics.controlSize
                leftIconSize: Style.iconSizeMedium
                backgroundColor: Style.surfaceContainerLowest
                borderWidth: 0
                focusedBorderWidth: Math.max(Style.outlineWidthFocused, Style.focusRingWidth)
                placeholderText: I18n.tr("Search...")
                onAccepted: root._focusFirstMatch()
                Keys.onReturnPressed: event => event.accepted = true
                Keys.onEnterPressed: event => event.accepted = true
                Keys.onDownPressed: root._focusFirstMatch()
                Keys.onEscapePressed: event => {
                    if (text === "") {
                        event.accepted = false;
                        return;
                    }
                    clear();
                    browser.focusBody();
                }
            }

            Row {
                id: rightActions

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: FileBrowserMetrics.controlSpacing

                FlatButton {
                    visible: topbar.searchCollapsed
                    iconName: "search"
                    tooltipText: I18n.tr("Search...")
                    onClicked: root.focusSearch()
                }

                FlatButton {
                    iconName: root.showHidden ? "visibility" : "visibility_off"
                    iconColor: root.showHidden ? Style.onSelectedContainer : Style.surfaceText
                    backgroundColor: root.showHidden ? root.selectedLayer : "transparent"
                    tooltipText: I18n.tr("Show hidden files", "file browser toolbar toggle")
                    Accessible.checked: root.showHidden
                    onClicked: root.setShowHidden(!root.showHidden)
                }
            }
        }

        CardSegment {
            id: listSegment

            anchors.top: topSegment.bottom
            anchors.bottom: statusSegment.top
            anchors.topMargin: Style.groupedListGap
            anchors.bottomMargin: Style.groupedListGap

            FileBrowserView {
                id: browser

                anchors.fill: parent
                focus: !root.saving
                backend: root.backend
                showSidebar: false
                showNavigation: false
                pathBarHost: pathSlot
                pathBarColor: Style.surfaceContainerLowest
                showHidden: root.showHidden
                filters: root.filters
                sortKey: root.sortKey
                sortDescending: root.sortDescending
                viewMode: root.viewMode
                gridZoom: root.gridZoom
                listZoom: root.listZoom
                listColumns: ["size", "modified"]
                multiSelect: root.multiple
                nameFilter: searchField.text
                typeAheadMode: "filter"
                emptyText: nameFilter !== "" ? I18n.tr("No matches") : I18n.tr("This folder is empty", "empty directory placeholder")
                escapeClearsSelection: false
                onPathChanged: {
                    root._error = "";
                    searchField.text = "";
                }
                onActivateRequested: entry => root.activate(entry)
                onFocusRequested: browser.focusBody()
                onFilterRequested: text => root._typeIntoSearch(text)
                onFilterFocusRequested: root.focusSearch()
                onSortRequested: key => root.setSort(key, key === root.sortKey ? !root.sortDescending : false)
                onZoomRequested: (forMode, level) => root.setZoom(forMode, level)
                onRenameRequested: (target, name) => root.renameItem(target, name)
                onItemMenuRequested: (index, pointX, pointY) => {
                    const entry = browser.body.entryAt(index);
                    if (!entry)
                        return;
                    itemMenu.entry = entry;
                    const point = browser.mapToItem(root, pointX, pointY);
                    itemMenu.openAt(point.x, point.y);
                }
                onBackgroundMenuRequested: (pointX, pointY) => {
                    const point = browser.mapToItem(root, pointX, pointY);
                    backgroundMenu.openAt(point.x, point.y);
                }
            }
        }

        CardSegment {
            id: statusSegment

            anchors.bottom: actionSegment.top
            anchors.bottomMargin: Style.groupedListGap
            height: FileBrowserMetrics.controlSize + FileBrowserMetrics.pickerCardPadding * 2
        }

        Item {
            id: statusBar

            anchors.fill: statusSegment
            anchors.margins: FileBrowserMetrics.pickerCardPadding

            StyledText {
                anchors.left: parent.left
                anchors.right: statusControls.left
                anchors.leftMargin: Style.spacingS
                anchors.rightMargin: Style.spacingS
                anchors.verticalCenter: parent.verticalCenter
                text: root.statusText
                color: Style.surfaceVariantText
                font.pixelSize: Style.fontSizeSmall
                wrapMode: Text.NoWrap
                elide: Text.ElideMiddle
            }

            Row {
                id: statusControls

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: FileBrowserMetrics.controlSpacing

                FileSortButton {
                    anchors.verticalCenter: parent.verticalCenter
                    sortKey: root.sortKey
                    descending: root.sortDescending
                    showLabel: statusBar.width >= Style.smallBreakpoint
                    tooltipSide: "top"
                    onSortKeySelected: key => root.setSort(key, root.sortDescending)
                    onDirectionToggled: root.setSort(root.sortKey, !root.sortDescending)
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: FileBrowserMetrics.navPairGap

                    Repeater {
                        model: root.viewModes

                        ControlSegment {
                            required property var modelData
                            required property int index

                            readonly property bool active: root.viewMode === modelData.value

                            joinStart: !active && index > 0
                            joinEnd: !active && index < root.viewModes.length - 1
                            color: active ? root.selectedLayer : Style.foregroundColor(Style.chipSurface, root.floating)
                            iconName: modelData.icon
                            iconColor: active ? Style.onSelectedContainer : Style.surfaceText
                            tooltipText: modelData.label
                            tooltipSide: "top"
                            Accessible.checked: active
                            onClicked: root.setViewMode(modelData.value)
                        }
                    }
                }
            }
        }

        CardSegment {
            id: actionSegment

            last: true
            anchors.bottom: parent.bottom
            height: footer.height + FileBrowserMetrics.pickerCardPadding * 2
        }

        Column {
            id: footer

            anchors.bottom: actionSegment.bottom
            anchors.left: actionSegment.left
            anchors.right: actionSegment.right
            anchors.margins: FileBrowserMetrics.pickerCardPadding
            spacing: Style.spacingS

            StyledText {
                width: parent.width
                visible: root._error !== ""
                text: root._error
                color: Style.error
                font.pixelSize: Style.fontSizeSmall
                elide: Text.ElideRight
            }

            Item {
                width: parent.width
                height: FileBrowserMetrics.controlSize

                DTextField {
                    id: nameField

                    anchors.left: parent.left
                    anchors.right: buttons.left
                    anchors.rightMargin: Style.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.saving
                    fieldHeight: FileBrowserMetrics.controlSize
                    cornerRadius: Style.fullRadius(width, height)
                    backgroundColor: Style.surfaceContainerLowest
                    borderWidth: 0
                    focusedBorderWidth: Math.max(Style.outlineWidthFocused, Style.focusRingWidth)
                    placeholderText: I18n.tr("Enter filename...", "file browser save filename input placeholder")
                    isError: text.trim() !== "" && !root.canAccept
                    onAccepted: root.acceptCurrent()
                    Keys.onReturnPressed: event => event.accepted = true
                    Keys.onEnterPressed: event => event.accepted = true
                    Keys.onEscapePressed: event => {
                        event.accepted = true;
                        root.rejected();
                    }
                }

                Row {
                    id: buttons

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.spacingS
                    LayoutMirroring.enabled: I18n.isRtl

                    DButton {
                        text: I18n.tr("Cancel", "file browser overwrite dialog cancel button")
                        variant: "text"
                        onClicked: root.rejected()
                    }

                    DButton {
                        enabled: root.canAccept
                        text: {
                            switch (root.mode) {
                            case "save":
                                return I18n.tr("Save", "file browser save button");
                            case "openFolder":
                                return I18n.tr("Use this folder", "file browser folder selection confirm button");
                            default:
                                return I18n.tr("Open", "file browser open button");
                            }
                        }
                        onClicked: root.acceptCurrent()
                    }
                }
            }
        }
    }

    FileMenu {
        id: itemMenu

        property var entry: null

        anchorItem: root

        FileMenuItem {
            visible: itemMenu.entry?.isDir === true
            iconName: "folder_open"
            text: I18n.tr("Open", "file browser open button")
            onClicked: {
                itemMenu.close();
                browser.navigate(itemMenu.entry.path);
            }
        }

        FileMenuItem {
            visible: root.capabilities.rename === true
            iconName: "edit"
            text: I18n.tr("Rename", "file browser item context menu action")
            onClicked: {
                itemMenu.close();
                browser.beginRename(itemMenu.entry.path);
            }
        }

        FileMenuItem {
            visible: root.capabilities.trash === true
            iconName: "delete"
            text: I18n.tr("Move to Trash", "file browser item context menu action")
            onClicked: {
                itemMenu.close();
                const target = itemMenu.entry.path;
                root.trashItems(browser.selection.contains(target) ? browser.selection.paths.slice() : [target]);
            }
        }

        FileMenuItem {
            iconName: "content_copy"
            text: I18n.tr("Copy path", "file browser item context menu action")
            onClicked: {
                itemMenu.close();
                Paths.copyPathToClipboard(itemMenu.entry.path);
            }
        }
    }

    FileMenu {
        id: backgroundMenu

        anchorItem: root

        FileMenuItem {
            visible: root.capabilities.mkdir === true
            iconName: "create_new_folder"
            text: I18n.tr("New folder", "file browser toolbar button creating a folder")
            onClicked: {
                backgroundMenu.close();
                newFolderDialog.show();
            }
        }

        FileMenuItem {
            iconName: "content_copy"
            text: I18n.tr("Copy path", "file browser item context menu action")
            onClicked: {
                backgroundMenu.close();
                Paths.copyPathToClipboard(browser.path);
            }
        }
    }

    DDialog {
        id: newFolderDialog

        function show() {
            folderName.text = "";
            opened = true;
            folderName.forceActiveFocus();
        }

        anchors.fill: parent
        embedded: false
        opened: false
        title: I18n.tr("New folder", "file browser toolbar button creating a folder")
        acceptEnabled: FileFormat.validName(folderName.text)
        onAccepted: root.createFolder(folderName.text)
        onRejected: {
            opened = false;
            root._focusStart();
        }

        DTextField {
            id: folderName

            width: parent.width
            outlined: true
            labelText: I18n.tr("Folder name", "label of the name field in the new folder dialog")
            onAccepted: {
                if (newFolderDialog.acceptEnabled)
                    root.createFolder(text);
            }
        }

        actions: [
            DButton {
                text: I18n.tr("Cancel", "file browser overwrite dialog cancel button")
                variant: "text"
                onClicked: newFolderDialog.rejected()
            },
            DButton {
                enabled: newFolderDialog.acceptEnabled
                text: I18n.tr("Create", "confirm button of the new folder dialog")
                onClicked: newFolderDialog.accepted()
            }
        ]
    }

    DDialog {
        id: overwriteDialog

        anchors.fill: parent
        embedded: false
        opened: root._overwriteTarget !== ""
        title: I18n.tr("File Already Exists", "file browser overwrite dialog title")
        supportingText: I18n.tr("A file with this name already exists. Do you want to overwrite it?", "file browser overwrite dialog message")
        onAccepted: {
            const target = root._overwriteTarget;
            root._overwriteTarget = "";
            root._finish([target]);
        }
        onRejected: {
            root._overwriteTarget = "";
            root._focusStart();
        }
        onOpenedChanged: {
            if (opened)
                forceActiveFocus();
        }

        actions: [
            DButton {
                text: I18n.tr("Cancel", "file browser overwrite dialog cancel button")
                variant: "text"
                onClicked: overwriteDialog.rejected()
            },
            DButton {
                text: I18n.tr("Overwrite", "file browser overwrite dialog confirm button")
                variant: "tonal"
                danger: true
                onClicked: overwriteDialog.accepted()
            }
        ]
    }
}
