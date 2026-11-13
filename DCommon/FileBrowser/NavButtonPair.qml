pragma ComponentBehavior: Bound

import QtQuick
import qs.DCommon.Common
import qs.DCommon.Widgets

Row {
    id: pair

    property bool backEnabled: false
    property bool forwardEnabled: false

    signal backRequested
    signal forwardRequested

    spacing: FileBrowserMetrics.navPairGap
    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    ControlSegment {
        joinEnd: true
        color: enabled ? Style.chipSurface : Style.onSurface_12
        enabled: pair.backEnabled
        iconName: I18n.isRtl ? "arrow_forward" : "arrow_back"
        tooltipText: I18n.tr("Back", "tooltip on the button going to the previous location")
        onClicked: pair.backRequested()
    }

    ControlSegment {
        joinStart: true
        color: enabled ? Style.chipSurface : Style.onSurface_12
        enabled: pair.forwardEnabled
        iconName: I18n.isRtl ? "arrow_back" : "arrow_forward"
        tooltipText: I18n.tr("Forward", "tooltip on the button going to the next location")
        onClicked: pair.forwardRequested()
    }
}
