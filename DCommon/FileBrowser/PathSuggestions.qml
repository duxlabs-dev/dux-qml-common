pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import qs.DCommon.Common
import qs.DCommon.Widgets

Popup {
    id: root

    property DTextField anchorItem: null
    property var rows: []
    property string errorText: ""
    property var shownRows: []
    property string shownError: ""
    property int highlightIndex: -1
    property real reveal: 1
    property real attachment: 0
    readonly property bool motionEnabled: FileBrowserMetrics.animationsEnabled
    readonly property real rowHeight: Style.menuRowHeight
    readonly property color containerColor: Style.chipSurface
    readonly property real cornerRadius: Math.min(anchorItem?.radius ?? Style.cornerRadiusL, height / 2)
    readonly property real borderWidth: anchorItem?.border.width ?? 0
    readonly property real seam: Math.ceil(anchorItem?.focusedBorderWidth ?? 0)
    readonly property real seamOverlap: Style.outlineWidth
    readonly property real overhangRadius: width > (anchorItem?.width ?? 0) ? cornerRadius : 0
    readonly property real foldedHeight: topPadding + bottomPadding

    signal chosen(var row)

    function move(delta) {
        const count = rows.length;
        if (count === 0)
            return;
        let next = highlightIndex + delta;
        if (next >= count)
            next = -1;
        if (next < -1)
            next = count - 1;
        highlightIndex = next;
    }

    function page(delta) {
        if (rows.length === 0)
            return;
        highlightIndex = Math.max(0, Math.min(rows.length - 1, highlightIndex + delta * FileBrowserMetrics.suggestionRows));
    }

    function highlightedRow() {
        return highlightIndex >= 0 && highlightIndex < rows.length ? rows[highlightIndex] : null;
    }

    function hold() {
        if (rows.length === 0 && errorText === "")
            return;
        shownRows = rows;
        shownError = errorText;
        list.resetScroll();
    }

    parent: anchorItem
    x: I18n.isRtl ? (anchorItem?.width ?? 0) - width : 0
    y: (anchorItem?.height ?? 0) - seam
    width: Math.max(anchorItem?.width ?? 0, FileBrowserMetrics.suggestionMinWidth)
    height: foldedHeight + (implicitHeight - foldedHeight) * reveal
    margins: 0
    padding: Style.spacingXS
    modal: false
    dim: false
    focus: false
    closePolicy: Popup.NoAutoClose
    onRowsChanged: {
        if (highlightIndex >= rows.length)
            highlightIndex = -1;
        hold();
    }
    onErrorTextChanged: hold()
    onAboutToShow: {
        detach.stop();
        reveal = 1;
        attachment = 1;
    }
    onClosed: detach.restart()
    onHighlightIndexChanged: {
        if (highlightIndex >= 0)
            list.revealIndex(highlightIndex);
    }

    enter: Transition {
        enabled: root.motionEnabled

        DAnim {
            target: root
            property: "reveal"
            from: 0
            to: 1
            duration: Style.expressiveDurations.expressiveEffects
            easing.bezierCurve: Style.expressiveCurves.expressiveEffects
        }
    }

    exit: Transition {
        enabled: root.motionEnabled

        DAnim {
            target: root
            property: "reveal"
            from: 1
            to: 0
            duration: Style.shorterDuration
            easing.bezierCurve: Style.expressiveCurves.emphasizedAccel
        }
    }

    DAnim {
        id: detach

        target: root
        property: "attachment"
        to: 0
        duration: root.motionEnabled ? Style.expressiveDurations.expressiveEffects : 0
        easing.bezierCurve: Style.expressiveCurves.expressiveEffects
    }

    background: Item {
        Item {
            anchors.fill: parent
            anchors.leftMargin: -shadow._pad
            anchors.rightMargin: -shadow._pad
            anchors.bottomMargin: -shadow._pad
            clip: true

            ElevationShadow {
                id: shadow

                x: _pad
                width: root.width
                height: root.height
                level: Style.elevationLevel2
                fallbackOffset: Style.spacingXS
                targetRadius: root.cornerRadius
                topLeftRadius: I18n.isRtl ? root.overhangRadius : 0
                topRightRadius: I18n.isRtl ? 0 : root.overhangRadius
                targetColor: root.containerColor
                borderColor: root.anchorItem?.border.color ?? "transparent"
                borderWidth: root.borderWidth
                shadowEnabled: Style.elevationEnabled && Style.popoutElevationEnabled
            }
        }

        Rectangle {
            x: root.seam
            y: -root.seamOverlap
            width: Math.min(parent.width, root.anchorItem?.width ?? 0) - root.seam * 2
            height: Math.max(root.seam, Style.dividerWidth) + root.seamOverlap * 2
            color: root.containerColor

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.seamOverlap
                width: parent.width
                height: Style.dividerWidth
                color: Style.outlineVariant
            }
        }
    }

    contentItem: Column {
        LayoutMirroring.enabled: I18n.isRtl
        LayoutMirroring.childrenInherit: true
        spacing: 0
        clip: true

        Item {
            width: parent.width
            height: root.rowHeight
            visible: root.shownError !== ""

            DIcon {
                id: errorIcon

                anchors.left: parent.left
                anchors.leftMargin: Style.spacingM
                anchors.verticalCenter: parent.verticalCenter
                name: "error"
                size: Style.menuItemIconSize
                color: Style.error
            }

            StyledText {
                anchors.left: errorIcon.right
                anchors.leftMargin: Style.spacingM
                anchors.right: parent.right
                anchors.rightMargin: Style.spacingM
                anchors.verticalCenter: parent.verticalCenter
                text: root.shownError
                color: Style.error
                font.pixelSize: Style.fontSizeMedium
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
            }
        }

        DListView {
            id: list

            width: parent.width
            height: Math.min(root.shownRows.length, FileBrowserMetrics.suggestionRows) * root.rowHeight
            visible: root.shownRows.length > 0
            clip: true
            model: root.shownRows

            delegate: StyledButton {
                id: entry

                required property var modelData
                required property int index

                width: ListView.view.width
                implicitHeight: root.rowHeight
                radius: Style.cornerRadiusS
                color: "transparent"
                focusPolicy: Qt.NoFocus
                onClicked: root.chosen(modelData)

                StateLayer {
                    control: entry
                    hovered: entry.hovered
                    focused: entry.index === root.highlightIndex
                    stateColor: Style.surfaceText
                }

                DIcon {
                    id: entryIcon

                    anchors.left: parent.left
                    anchors.leftMargin: Style.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    name: entry.modelData.kind === "visited" ? "history" : "folder"
                    size: Style.menuItemIconSize
                    color: Style.surfaceVariantText
                }

                StyledText {
                    id: entryHint

                    anchors.right: parent.right
                    anchors.rightMargin: Style.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, parent.width * FileBrowserMetrics.suggestionHintRatio)
                    visible: entry.modelData.hint !== ""
                    text: FileFormat.markRanges(entry.modelData.hint, entry.modelData.hintMarks, Style.primary)
                    textFormat: Text.StyledText
                    color: Style.surfaceVariantText
                    font.pixelSize: Style.fontSizeSmall
                    horizontalAlignment: Text.AlignRight
                    wrapMode: Text.NoWrap
                    elide: Text.ElideLeft
                }

                StyledText {
                    anchors.left: entryIcon.right
                    anchors.leftMargin: Style.spacingM
                    anchors.right: entryHint.visible ? entryHint.left : parent.right
                    anchors.rightMargin: Style.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    text: FileFormat.markRanges(entry.modelData.name, entry.modelData.nameMarks, Style.primary)
                    textFormat: Text.StyledText
                    color: Style.surfaceText
                    font.pixelSize: Style.fontSizeMedium
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }
            }
        }
    }
}
