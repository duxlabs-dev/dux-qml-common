import QtQuick
import qs.DCommon.Common

Rectangle {
    property bool animate: true
    property bool firstInGroup: true
    property bool lastInGroup: true
    color: Style.selectedContainer
    radius: Style.groupedListInnerRadius
    topLeftRadius: firstInGroup ? Style.groupedListOuterRadius : radius
    topRightRadius: topLeftRadius
    bottomLeftRadius: lastInGroup ? Style.groupedListOuterRadius : radius
    bottomRightRadius: bottomLeftRadius

    Behavior on x {
        enabled: parent && parent.visible && animate && !Style.reduceMotion
        NumberAnimation {
            duration: Style.expressiveDurations.expressiveFastEffects
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Style.expressiveCurves.expressiveFastEffects
        }
    }
    Behavior on y {
        enabled: parent && parent.visible && animate && !Style.reduceMotion
        NumberAnimation {
            duration: Style.expressiveDurations.expressiveFastEffects
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Style.expressiveCurves.expressiveFastEffects
        }
    }
}
