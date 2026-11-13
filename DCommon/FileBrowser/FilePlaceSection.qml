pragma ComponentBehavior: Bound

import QtQuick
import qs.DCommon.Common
import qs.DCommon.Widgets

Column {
    id: section

    property string title: ""
    property string emptyText: ""
    property bool showEmpty: false

    default property alias rows: body.data

    readonly property bool iconOnly: width < FileBrowserMetrics.sidebarIconOnlyBelow

    spacing: FileBrowserMetrics.sidebarRowGap

    StyledText {
        visible: !section.iconOnly
        text: section.title
        color: Style.surfaceVariantText
        font.pixelSize: Style.fontSizeSmall
        font.weight: Style.fontWeightMedium
        leftPadding: Style.spacingM
        bottomPadding: Style.spacingXXS
    }

    Column {
        id: body

        width: section.width
        spacing: FileBrowserMetrics.sidebarRowGap
    }

    StyledText {
        width: section.width
        visible: section.showEmpty && section.emptyText !== "" && !section.iconOnly
        text: section.emptyText
        color: Style.surfaceVariantText
        font.pixelSize: Style.fontSizeSmall
        leftPadding: Style.spacingM
        rightPadding: Style.spacingM
        wrapMode: Text.Wrap
    }
}
