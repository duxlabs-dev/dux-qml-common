pragma ComponentBehavior: Bound

import QtQuick
import qs.DCommon.Common

Item {
    id: root

    property alias model: repeater.model
    property alias delegate: repeater.delegate
    readonly property int count: repeater.count
    property real spacing: Style.groupedListGap
    property var flickable: null
    property int columns: 1
    property var group: null
    readonly property var activeGroup: columns > 1 ? null : group
    property string groupKey: ""
    property Item dropArea: root
    property bool externalDrag: activeGroup !== null
    property bool crossSectionActive: false
    property int gapIndex: -1
    property real gapHeight: Style.listItemTwoLineHeight
    property var order: []
    property int draggingIndex: -1
    property real pressOffset: 0
    property real pressOffsetX: 0
    property real pointerX: 0
    property real pointerY: 0
    property int focusIndex: -1
    property var positions: []
    property int delegateRevision: 0
    property bool animateLayout: false
    property int focusReason: Qt.OtherFocusReason
    readonly property bool mirrored: I18n.isRtl

    signal reordered(var indices)
    signal dragStarted(int index, point position)
    signal dragMoved(point position)
    signal dragFinished
    signal dragCanceled

    implicitHeight: 0
    height: implicitHeight
    width: parent?.width ?? 0

    function itemAt(index) {
        return repeater.itemAt(index);
    }

    function identityOrder() {
        return Array.from({
            length: count
        }, (_, i) => i);
    }

    function reset() {
        animateLayout = false;
        cancel();
        layout();
    }

    function layout() {
        if (columns > 1) {
            layoutGrid();
            return;
        }
        let cursor = 0;
        const next = [];
        for (let slot = 0; slot < order.length; slot++) {
            if (slot === gapIndex)
                cursor += gapHeight + spacing;
            const index = order[slot];
            const item = itemAt(index);
            next[index] = cursor;
            if (!item)
                continue;
            item.width = width;
            if (index !== draggingIndex)
                item.y = cursor;
            cursor += item.height + spacing;
        }
        if (gapIndex === order.length)
            cursor += gapHeight + spacing;
        positions = next;
        implicitHeight = Math.max(0, cursor - spacing);
    }

    function layoutGrid() {
        const cellWidth = Math.max(0, (width - spacing * (columns - 1)) / columns);
        const next = [];
        let top = 0;
        for (let start = 0; start < order.length; start += columns) {
            const row = order.slice(start, start + columns);
            row.forEach(index => {
                const item = itemAt(index);
                if (item)
                    item.width = cellWidth;
            });
            const rowHeight = Math.max(0, ...row.map(index => itemAt(index)?.height ?? 0));
            row.forEach((index, offset) => {
                const x = (mirrored ? columns - 1 - offset : offset) * (cellWidth + spacing);
                // The last cell also covers the empty cells after it, so dropping there moves an item to the end.
                const span = offset === row.length - 1 ? columns - offset : 1;
                const spanWidth = span * cellWidth + (span - 1) * spacing;
                next[index] = Qt.rect(mirrored ? x + cellWidth - spanWidth : x, top, spanWidth, rowHeight);
                const item = itemAt(index);
                if (!item)
                    return;
                if (index !== draggingIndex) {
                    item.x = x;
                    item.y = top;
                }
            });
            top += rowHeight + spacing;
        }
        positions = next;
        implicitHeight = Math.max(0, top - spacing);
    }

    function listTarget(item, from) {
        let target = from;
        for (let slot = 0; slot < order.length; slot++) {
            const index = order[slot];
            if (slot === from)
                continue;
            const other = itemAt(index);
            if (!other)
                continue;
            const middle = positions[index] + other.height / 2;
            if (slot < from && item.y < middle)
                target = Math.min(target, slot);
            if (slot > from && item.y + item.height > middle)
                target = Math.max(target, slot);
        }
        return target;
    }

    // The current slot is kept while the pointer is in the spacing between cells, so it can't flicker at a boundary.
    function gridTarget(from) {
        let target = from;
        let nearest = Infinity;
        for (let slot = 0; slot < order.length; slot++) {
            const index = order[slot];
            const cell = positions[index];
            if (!cell)
                continue;
            const dx = Math.max(cell.x - pointerX, pointerX - cell.x - cell.width, 0);
            const dy = Math.max(cell.y - pointerY, pointerY - cell.y - cell.height, 0);
            const distance = Math.hypot(dx, dy);
            if (distance < nearest) {
                nearest = distance;
                target = slot;
            }
        }
        return nearest === 0 || nearest > spacing ? target : from;
    }

    function insertionIndex(y) {
        for (let slot = 0; slot < order.length; slot++) {
            const index = order[slot];
            const item = itemAt(index);
            if (item && y < positions[index] + item.height / 2)
                return slot;
        }
        return count;
    }

    function begin(index, position) {
        const item = itemAt(index);
        if (!item || !enabled)
            return;
        animateLayout = true;
        focusReason = Qt.MouseFocusReason;
        draggingIndex = index;
        pressOffset = position.y - item.y;
        pressOffsetX = position.x - item.x;
        pointerX = position.x;
        pointerY = position.y;
        dragStarted(index, position);
    }

    function dragTo(position) {
        const item = itemAt(draggingIndex);
        if (!item)
            return;
        pointerX = position.x;
        pointerY = position.y;
        const clamp = (value, max) => externalDrag ? value : Math.max(0, Math.min(max, value));
        if (columns > 1)
            item.x = clamp(position.x - pressOffsetX, width - item.width);
        item.y = clamp(position.y - pressOffset, height - item.height);
        dragMoved(position);
        if (crossSectionActive)
            return;
        const from = order.indexOf(draggingIndex);
        if (from < 0)
            return;
        const target = columns > 1 ? gridTarget(from) : listTarget(item, from);
        if (target === from)
            return;
        const next = order.slice();
        next.splice(from, 1);
        next.splice(target, 0, draggingIndex);
        order = next;
    }

    function finish() {
        if (draggingIndex < 0)
            return;
        if (externalDrag) {
            dragFinished();
            return;
        }
        commit();
    }

    function commit() {
        if (draggingIndex < 0)
            return;
        const next = order.slice();
        focusIndex = next.indexOf(draggingIndex);
        draggingIndex = -1;
        crossSectionActive = false;
        gapIndex = -1;
        layout();
        if (next.some((index, slot) => index !== slot))
            reordered(next);
        order = identityOrder();
        focusTimer.restart();
    }

    function cancel() {
        const active = draggingIndex >= 0;
        draggingIndex = -1;
        crossSectionActive = false;
        gapIndex = -1;
        order = identityOrder();
        root.layout();
        if (active)
            dragCanceled();
    }

    function move(index, delta) {
        const target = index + delta;
        if (!enabled || draggingIndex >= 0 || index < 0 || index >= count || target < 0 || target >= count)
            return;
        const next = identityOrder();
        next.splice(index, 1);
        next.splice(target, 0, index);
        focusIndex = target;
        focusReason = Qt.TabFocusReason;
        reordered(next);
        order = identityOrder();
        focusTimer.restart();
    }

    onDragStarted: (index, position) => activeGroup?.begin(root, index, position)
    onDragMoved: position => activeGroup?.move(position)
    onDragFinished: activeGroup?.finish()
    onDragCanceled: activeGroup?.cancel()

    Component.onCompleted: activeGroup?.registerList(root)
    Component.onDestruction: group?.unregisterList(root)

    onModelChanged: reset()
    onCountChanged: reset()
    onOrderChanged: root.layout()
    onWidthChanged: root.layout()
    onColumnsChanged: {
        if (columns > 1) {
            group?.unregisterList(root);
        } else {
            group?.registerList(root);
            for (let i = 0; i < count; i++) {
                const item = itemAt(i);
                if (item)
                    item.x = 0;
            }
        }
        root.layout();
    }
    onMirroredChanged: root.layout()
    onSpacingChanged: root.layout()
    onGapIndexChanged: {
        if (gapIndex >= 0)
            animateLayout = true;
        root.layout();
    }
    onGapHeightChanged: root.layout()
    onCrossSectionActiveChanged: {
        if (crossSectionActive)
            order = identityOrder();
    }
    onVisibleChanged: {
        if (!visible)
            cancel();
    }
    onEnabledChanged: {
        if (!enabled) {
            cancel();
            return;
        }
        focusTimer.restart();
    }

    Repeater {
        id: repeater
        onItemAdded: {
            root.delegateRevision++;
            root.layout();
        }
        onItemRemoved: root.delegateRevision++
    }

    Instantiator {
        model: root.count
        QtObject {
            required property int index
            readonly property real itemHeight: {
                root.delegateRevision;
                return root.itemAt(index)?.height ?? 0;
            }
            onItemHeightChanged: root.layout()
        }
    }

    Timer {
        id: focusTimer
        interval: 0
        onTriggered: {
            if (!root.enabled)
                return;
            const item = root.itemAt(root.focusIndex);
            root.focusIndex = -1;
            if (!item)
                return;
            if (typeof item.focusHandle === "function")
                item.focusHandle(root.focusReason);
        }
    }

    Timer {
        interval: Timing.cappedTick
        repeat: true
        running: root.draggingIndex >= 0 && root.visible && !!root.flickable
        onTriggered: {
            const view = root.flickable;
            const point = root.mapToItem(view, 0, root.pointerY);
            const edge = Style.listItemHeight;
            const speed = point.y < edge ? -Math.min(1, (edge - point.y) / edge) : (point.y > view.height - edge ? Math.min(1, (point.y - view.height + edge) / edge) : 0);
            if (speed === 0)
                return;
            const before = view.contentY;
            view.contentY = Math.max(view.originY, Math.min(view.originY + Math.max(0, view.contentHeight - view.height), before + speed * Style.spacingM));
            const delta = view.contentY - before;
            if (delta !== 0)
                root.dragTo(Qt.point(root.pointerX, root.pointerY + delta));
        }
    }
}
