import QtQuick

// Reusable ColorAnimation wrapper
ColorAnimation {
    duration: Style.expressiveDurations.expressiveEffects
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Style.expressiveCurves.expressiveEffects
}
