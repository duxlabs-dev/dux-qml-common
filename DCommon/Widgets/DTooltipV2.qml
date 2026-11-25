import QtQuick
import QtQuick.Controls
import QtQuick.Window
import qs.DCommon.Common

Item {
    id: root

    property string text: ""
    property bool multiline: false
    property alias delay: tooltip.delay
    property Item sourceItem: null
    readonly property var sourceWindow: sourceItem?.Window.window ?? null
    readonly property bool presenting: tooltip.visible

    onSourceItemChanged: {
        if (!sourceItem)
            root.fadeOut();
    }

    function show(text, item, offsetX, offsetY, preferredSide) {
        if (!item || !item.visible) {
            hide();
            return;
        }

        let windowContentItem = item.Window?.window?.contentItem;
        if (!windowContentItem) {
            let current = item;
            while (current) {
                if (current.Window?.window?.contentItem) {
                    windowContentItem = current.Window.window.contentItem;
                    break;
                }
                current = current.parent;
            }
        }
        if (!windowContentItem)
            return;

        root.sourceItem = item;
        tooltip.parent = windowContentItem;
        tooltip.text = text;

        // Mapped box, so rotated or scaled targets get the tooltip beside them.
        const box = item.mapToItem(windowContentItem, Qt.rect(0, 0, item.width, item.height));
        const parentWidth = windowContentItem.width;
        const parentHeight = windowContentItem.height;
        const tooltipWidth = tooltip.implicitWidth;
        const tooltipHeight = tooltip.implicitHeight;
        const gap = Style.spacingS;

        const side = preferredSide || _determineBestSide(box, parentWidth, parentHeight, tooltipWidth, tooltipHeight);

        let targetX = 0;
        let targetY = 0;

        switch (side) {
        case "left":
            targetX = box.x - tooltipWidth - gap;
            targetY = box.y + (box.height - tooltipHeight) / 2;
            break;
        case "right":
            targetX = box.x + box.width + gap;
            targetY = box.y + (box.height - tooltipHeight) / 2;
            break;
        case "top":
            targetX = box.x + (box.width - tooltipWidth) / 2;
            targetY = box.y - tooltipHeight - gap;
            break;
        case "bottom":
        default:
            targetX = box.x + (box.width - tooltipWidth) / 2;
            targetY = box.y + box.height + gap;
            break;
        }

        tooltip.x = Math.max(Style.spacingXS, Math.min(parentWidth - tooltipWidth - Style.spacingXS, targetX + (offsetX || 0)));
        tooltip.y = Math.max(Style.spacingXS, Math.min(parentHeight - tooltipHeight - Style.spacingXS, targetY + (offsetY || 0)));

        if (tooltip.visible) {
            root.reveal();
            return;
        }
        tooltip.open();
    }

    function _determineBestSide(box, parentWidth, parentHeight, tooltipWidth, tooltipHeight) {
        const itemCenterX = box.x + box.width / 2;
        const margin = Style.spacingL;

        const spaceLeft = box.x;
        const spaceRight = parentWidth - (box.x + box.width);
        const spaceTop = box.y;
        const spaceBottom = parentHeight - (box.y + box.height);

        if (spaceRight >= tooltipWidth + margin)
            return "right";
        if (spaceLeft >= tooltipWidth + margin)
            return "left";
        if (spaceBottom >= tooltipHeight + margin)
            return "bottom";
        if (spaceTop >= tooltipHeight + margin)
            return "top";
        if (itemCenterX > parentWidth / 2)
            return "left";
        return "right";
    }

    function hide() {
        root.sourceItem = null;
        root.fadeOut();
    }

    function reveal() {
        scaleMotion.retarget(1);
        fadeMotion.retarget(1);
    }

    function fadeOut() {
        if (!tooltip.visible) {
            tooltip.close();
            return;
        }
        scaleMotion.retarget(Style.tooltipEnterScale);
        fadeMotion.retarget(0);
        if (!fadeMotion.running)
            tooltip.close();
    }

    onVisibleChanged: {
        if (!visible)
            hide();
    }
    Component.onDestruction: tooltip.close()

    Connections {
        target: root.sourceItem
        function onVisibleChanged() {
            if (!root.sourceItem?.visible)
                root.hide();
        }
    }

    Connections {
        target: root.sourceWindow
        function onVisibleChanged() {
            if (!root.sourceWindow?.visible)
                root.hide();
        }
    }

    SpringMotion {
        id: scaleMotion
        value: 1
        stiffness: Style.springPreset("fastSpatial").stiffness
        damping: Style.springPreset("fastSpatial").damping
    }

    SpringMotion {
        id: fadeMotion
        value: 1
        stiffness: Style.springPreset("fastEffects").stiffness
        damping: Style.springPreset("fastEffects").damping
        onRunningChanged: {
            if (!running && target === 0)
                tooltip.close();
        }
    }

    ToolTip {
        id: tooltip

        opacity: Math.max(0, Math.min(1, fadeMotion.value))
        scale: scaleMotion.value
        enter: null
        exit: null
        onAboutToShow: {
            scaleMotion.snapTo(Style.tooltipEnterScale);
            fadeMotion.snapTo(0);
            root.reveal();
        }

        implicitWidth: Math.min(textContent.implicitWidth, Style.tooltipMaxWidth) + leftPadding + rightPadding
        leftPadding: Style.spacingM
        rightPadding: Style.spacingM
        topPadding: Style.spacingS
        bottomPadding: Style.spacingS
        margins: Style.spacingXS
        closePolicy: Popup.NoAutoClose
        modal: false
        dim: false

        Binding {
            target: tooltip.contentItem?.parent ?? null
            property: "containmentMask"
            value: QtObject {
                function contains(position: point): bool {
                    return false;
                }
            }
        }

        background: Rectangle {
            color: Style.tooltipSurface
            radius: Style.cornerRadiusXS
        }

        contentItem: Text {
            id: textContent

            width: Math.min(implicitWidth, Style.tooltipMaxWidth)
            text: tooltip.text
            font.pixelSize: Style.fontSizeSmall
            font.family: Style.fontFamily
            color: Style.tooltipText
            textFormat: root.multiline ? Text.PlainText : Text.AutoText
            wrapMode: root.multiline ? Text.WrapAnywhere : Text.NoWrap
            maximumLineCount: root.multiline ? 2147483647 : 1
            elide: root.multiline ? Text.ElideNone : Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
