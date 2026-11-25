import QtQuick
import qs.DCommon.Common

// One segment of a connected button row; children are its content, colored with contentColor.
StyledButton {
    id: root

    property bool first: false
    property bool last: false
    property real outerRadius: Style.pillControls ? Style.fullRadius(height, height) : Style.cornerRadiusL
    property real innerRadius: Style.pillControls ? Math.min(Style.innerRadius("s"), outerRadius) : outerRadius
    property real pressedInnerRadius: Math.min(Style.innerRadius("xs"), outerRadius)
    property bool animateShape: true
    property bool animateColor: true
    property color selectedColor: Style.buttonBg
    property color selectedContentColor: Style.buttonText
    property color unselectedColor: Style.foregroundColor(Style.secondaryContainer, !Style.isFloatingWindow(root))
    property color unselectedContentColor: Style.onSecondaryContainer
    property color focusRingColor: Style.focusRingColor
    property string tooltipText: ""

    readonly property real joinRadius: !Style.shapeMorph ? innerRadius : (pressed ? pressedInnerRadius : (checked ? outerRadius : innerRadius))
    readonly property real startRadius: first ? outerRadius : joinRadius
    readonly property real endRadius: last ? outerRadius : joinRadius
    readonly property color contentColor: !enabled ? Style.onSurface_38 : (checked ? selectedContentColor : unselectedContentColor)

    Accessible.role: Accessible.RadioButton
    Accessible.name: text
    checkable: true

    color: !enabled ? Style.onSurface_10 : (checked ? selectedColor : unselectedColor)
    border.color: "transparent"
    border.width: 0

    topLeftRadius: mirrored ? endRadius : startRadius
    bottomLeftRadius: mirrored ? endRadius : startRadius
    topRightRadius: mirrored ? startRadius : endRadius
    bottomRightRadius: mirrored ? startRadius : endRadius

    Behavior on topLeftRadius {
        enabled: root.animateShape && !Style.reduceMotion
        DAnim {
            duration: Style.expressiveDurations.expressiveSlowEffects
            easing.bezierCurve: Style.expressiveCurves.expressiveSlowEffects
        }
    }

    Behavior on topRightRadius {
        enabled: root.animateShape && !Style.reduceMotion
        DAnim {
            duration: Style.expressiveDurations.expressiveSlowEffects
            easing.bezierCurve: Style.expressiveCurves.expressiveSlowEffects
        }
    }

    Behavior on bottomLeftRadius {
        enabled: root.animateShape && !Style.reduceMotion
        DAnim {
            duration: Style.expressiveDurations.expressiveSlowEffects
            easing.bezierCurve: Style.expressiveCurves.expressiveSlowEffects
        }
    }

    Behavior on bottomRightRadius {
        enabled: root.animateShape && !Style.reduceMotion
        DAnim {
            duration: Style.expressiveDurations.expressiveSlowEffects
            easing.bezierCurve: Style.expressiveCurves.expressiveSlowEffects
        }
    }

    Behavior on color {
        enabled: root.animateColor && !Style.reduceMotion
        DColorAnim {
            duration: Style.expressiveDurations.expressiveEffects
            easing.bezierCurve: Style.expressiveCurves.expressiveEffects
        }
    }

    StateLayer {
        control: root
        enabled: root.enabled
        disabled: !root.enabled
        stateColor: root.contentColor
        transitionDuration: Style.expressiveDurations.expressiveEffects
        transitionCurve: Style.expressiveCurves.expressiveEffects
        tooltipText: root.tooltipText
    }

    FocusRing {
        radius: Math.min(Style.fullRadius(width, height), root.outerRadius + Style.focusRingOffset)
        visible: root.visualFocus
        border.color: root.focusRingColor
    }
}
