pragma ComponentBehavior: Bound

import QtQuick
import qs.DCommon.Common
import qs.DCommon.Widgets

StyledButton {
    id: segment

    property bool joinStart: false
    property bool joinEnd: false
    property string iconName: ""
    property color iconColor: Style.surfaceText
    property string tooltipText: ""
    property string tooltipSide: "bottom"

    readonly property real outerRadius: Style.fullRadius(width, height)
    readonly property real startRadius: joinStart ? FileBrowserMetrics.navPairInnerRadius : outerRadius
    readonly property real endRadius: joinEnd ? FileBrowserMetrics.navPairInnerRadius : outerRadius

    focusPolicy: Qt.TabFocus
    width: FileBrowserMetrics.navPairSegmentWidth
    height: FileBrowserMetrics.controlSize
    color: Style.chipSurface
    topLeftRadius: mirrored ? endRadius : startRadius
    bottomLeftRadius: mirrored ? endRadius : startRadius
    topRightRadius: mirrored ? startRadius : endRadius
    bottomRightRadius: mirrored ? startRadius : endRadius
    Accessible.name: tooltipText

    component Morph: Behavior {
        enabled: FileBrowserMetrics.animationsEnabled

        DAnim {
            duration: Style.expressiveDurations.expressiveEffects
            easing.bezierCurve: Style.expressiveCurves.expressiveEffects
        }
    }

    Morph on topLeftRadius {}
    Morph on bottomLeftRadius {}
    Morph on topRightRadius {}
    Morph on bottomRightRadius {}

    StateLayer {
        control: segment
        disabled: !segment.enabled
        stateColor: segment.iconColor
        tooltipText: segment.tooltipText
        tooltipSide: segment.tooltipSide
    }

    DIcon {
        anchors.centerIn: parent
        visible: segment.iconName !== ""
        name: segment.iconName
        size: Style.iconSizeMedium
        color: segment.enabled ? segment.iconColor : Style.onSurface_38
    }

    FocusRing {
        visible: segment.visualFocus
        radius: segment.outerRadius
    }
}
