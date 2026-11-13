pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import qs.DCommon.Common
import qs.DCommon.Widgets

Popup {
    id: root

    property Item anchorItem: parent
    property Item highlightedItem: null
    default property alias rows: column.children
    property Popup parentMenu: null
    property Popup submenu: null
    property Item submenuRow: null
    property Item pointedRow: null
    property bool coversParent: false
    property string backText: I18n.tr("Back", "menu row that returns to the parent menu")

    readonly property bool motionEnabled: FileBrowserMetrics.animationsEnabled

    function openAt(pointX, pointY) {
        x = pointX;
        y = pointY;
        open();
    }

    function openSubmenu(child, row) {
        const source = row ?? activeRow();
        const fromKeys = highlightedItem !== null && highlightedItem === source;
        closeSubmenu();
        submenu = child;
        submenuRow = source;
        highlight(source);
        child.openBeside(root, source);
        if (fromKeys)
            child.highlightEdge(false);
    }

    function closeSubmenu() {
        const child = submenu;
        submenu = null;
        submenuRow = null;
        if (child)
            child.close();
    }

    function openBeside(menu, row) {
        const host = parent;
        const frame = menu.background;
        const edge = frame.mapToItem(null, 0, 0);
        const after = edge.x + frame.width - FileBrowserMetrics.submenuOverlap;
        const before = edge.x + FileBrowserMetrics.submenuOverlap - width;
        const fitsAfter = after + width <= frame.Window.width;
        const fitsBefore = before >= 0;
        const preferAfter = I18n.isRtl ? !fitsBefore : fitsAfter || !fitsBefore;
        const top = row ? row.mapToItem(null, 0, 0).y - topPadding : edge.y;
        const point = host.mapFromItem(null, preferAfter ? after : before, top);
        parentMenu = menu;
        coversParent = !fitsAfter && !fitsBefore;
        openAt(point.x, point.y);
    }

    function leaveSubmenu() {
        closeSubmenu();
        flick.forceActiveFocus();
    }

    function back() {
        if (parentMenu)
            parentMenu.leaveSubmenu();
    }

    function activeRow() {
        if (highlightedItem && highlightedItem !== submenuRow)
            return highlightedItem;
        return navigableItems().find(item => item.hovered) ?? highlightedItem;
    }

    function rowAt(sceneX, sceneY) {
        return navigableItems().find(item => item.contains(item.mapFromItem(null, sceneX, sceneY))) ?? null;
    }

    function aimsAtSubmenu(deltaX, deltaY) {
        if (!submenu)
            return false;
        const side = submenu.background.mapToItem(null, 0, 0).x > background.mapToItem(null, 0, 0).x ? 1 : -1;
        return deltaX * side > Math.abs(deltaY) * FileBrowserMetrics.submenuAimSlope;
    }

    function pointAt(row, aiming) {
        if (row === pointedRow)
            return;
        pointedRow = row;
        submenuIntent.stop();
        if (!row || row === submenuRow)
            return;
        if (submenu && !aiming) {
            followPointer();
            return;
        }
        submenuIntent.restart();
    }

    function followPointer() {
        const row = pointedRow;
        if (!row || row === submenuRow)
            return;
        if (row.submenu) {
            row.click();
            return;
        }
        if (!submenu)
            return;
        leaveSubmenu();
        highlight(null);
    }

    function navigableItems() {
        const found = [];
        collectItems(column, found);
        return found;
    }

    function collectItems(item, out) {
        for (const child of item.children) {
            if (!child.visible)
                continue;
            if (child instanceof FileMenuItem) {
                if (child.enabled)
                    out.push(child);
                continue;
            }
            collectItems(child, out);
        }
    }

    function highlight(item) {
        if (highlightedItem)
            highlightedItem.highlighted = false;
        highlightedItem = item;
        if (!item)
            return;
        item.highlighted = true;
        const top = item.mapToItem(column, 0, 0).y;
        const bottom = top + item.height;
        if (top < flick.contentY) {
            flick.contentY = top;
            return;
        }
        if (bottom > flick.contentY + flick.height)
            flick.contentY = bottom - flick.height;
    }

    function moveHighlight(step) {
        const items = navigableItems();
        if (items.length === 0)
            return;
        const current = items.indexOf(highlightedItem);
        if (current < 0) {
            highlight(step > 0 ? items[0] : items[items.length - 1]);
            return;
        }
        highlight(items[(current + step + items.length) % items.length]);
    }

    function highlightEdge(last) {
        const items = navigableItems();
        if (items.length === 0)
            return;
        highlight(last ? items[items.length - 1] : items[0]);
    }

    width: FileBrowserMetrics.menuWidth
    padding: Style.spacingXS
    margins: 0
    modal: parentMenu === null
    dim: false
    focus: true
    closePolicy: parentMenu ? Popup.NoAutoClose : Popup.CloseOnEscape | Popup.CloseOnPressOutside
    onAboutToShow: {
        highlight(null);
        pointedRow = null;
        flick.contentY = 0;
    }
    onAboutToHide: {
        closeSubmenu();
        if (parentMenu?.submenu !== root)
            return;
        parentMenu.submenu = null;
        parentMenu.submenuRow = null;
        parentMenu.close();
    }
    onClosed: {
        parentMenu = null;
        coversParent = false;
    }

    background: Item {
        ElevationShadow {
            anchors.fill: parent
            level: Style.elevationLevel2
            fallbackOffset: Style.spacingXS
            targetRadius: Style.cornerRadiusL
            targetColor: Style.surfaceContainer
            borderColor: Style.outlineMedium
            borderWidth: Style.layerOutlineWidth
            shadowEnabled: Style.elevationEnabled && Style.popoutElevationEnabled
        }
    }

    contentItem: DFlickable {
        id: flick

        implicitHeight: Math.min(column.height, Math.max(Style.menuItemHeight * 3, flick.Window.height - FileBrowserMetrics.menuMargin * 2))
        contentWidth: width
        contentHeight: column.height
        clip: true
        focus: true

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Down:
            case Qt.Key_J:
                root.moveHighlight(1);
                break;
            case Qt.Key_Up:
            case Qt.Key_K:
                root.moveHighlight(-1);
                break;
            case Qt.Key_Left:
            case Qt.Key_Backspace:
            case Qt.Key_Escape:
                if (!root.parentMenu)
                    return;
                root.back();
                break;
            case Qt.Key_Right:
                if (!root.highlightedItem?.submenu)
                    return;
                root.highlightedItem.click();
                break;
            case Qt.Key_Home:
                root.highlightEdge(false);
                break;
            case Qt.Key_End:
                root.highlightEdge(true);
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space:
                if (!root.highlightedItem)
                    return;
                root.highlightedItem.click();
                break;
            default:
                return;
            }
            event.accepted = true;
        }

        HoverHandler {
            property point restingSpot

            // A resting pointer keeps reporting point changes.
            onPointChanged: {
                const spot = point.scenePosition;
                const deltaX = spot.x - restingSpot.x;
                const deltaY = spot.y - restingSpot.y;
                if (deltaX === 0 && deltaY === 0)
                    return;
                restingSpot = spot;
                if (root.highlightedItem && root.highlightedItem !== root.submenuRow)
                    root.highlight(null);
                root.pointAt(root.rowAt(spot.x, spot.y), root.aimsAtSubmenu(deltaX, deltaY));
            }
            onHoveredChanged: {
                if (!hovered)
                    root.pointedRow = null;
            }
        }

        Timer {
            id: submenuIntent

            interval: FileBrowserMetrics.submenuDelay
            onTriggered: root.followPointer()
        }

        Column {
            id: column

            width: parent.width
            spacing: 0

            FileMenuItem {
                visible: root.coversParent
                iconName: "arrow_back"
                text: root.backText
                onClicked: root.back()
            }

            FileMenuDivider {
                visible: root.coversParent
            }
        }
    }

    enter: Transition {
        enabled: root.motionEnabled

        DAnim {
            property: "opacity"
            from: 0
            to: 1
            duration: Style.expressiveDurations.expressiveEffects
            easing.bezierCurve: Style.expressiveCurves.expressiveEffects
        }
    }

    exit: Transition {
        enabled: root.motionEnabled

        DAnim {
            property: "opacity"
            from: 1
            to: 0
            duration: Style.shorterDuration
            easing.bezierCurve: Style.expressiveCurves.expressiveEffects
        }
    }
}
