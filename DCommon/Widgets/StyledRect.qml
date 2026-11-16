import QtQuick
import qs.DCommon.Common

Rectangle {
    color: "transparent"
    radius: Style.cornerRadiusM

    Behavior on opacity {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }
}
