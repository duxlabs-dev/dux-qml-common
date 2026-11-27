pragma ComponentBehavior: Bound

import QtQuick
import qs.DCommon.Common

Item {
    id: root

    property bool indeterminate: false
    property real value: 0
    property color color: Style.primary
    property color trackColor: Style.secondaryContainer
    property real thickness: Style.linearProgressThickness
    property real gapSize: Style.linearProgressGapSize
    property bool showStopIndicator: true

    readonly property real clampedValue: {
        const v = Number(value);
        return isNaN(v) ? 0 : Math.max(0, Math.min(1, v));
    }
    property real shownValue: clampedValue
    // M3 indeterminate cycle; the line ends below are offsets within it
    readonly property int cycleMs: 1750
    readonly property bool animating: indeterminate && !Style.reduceMotion && visible && (Window.window?.visible ?? false)

    // Ends of the two indeterminate lines, 0..1 of the width; line 2 always trails line 1
    property real head1: 0
    property real tail1: 0
    property real head2: 0
    property real tail2: 0

    readonly property real l1s: tail1 * width
    readonly property real l1e: head1 * width
    readonly property real l2s: tail2 * width
    readonly property real l2e: head2 * width
    readonly property bool l1on: animating && l1e - l1s > 0.5
    readonly property bool l2on: animating && l2e - l2s > 0.5

    implicitHeight: thickness
    Accessible.role: Accessible.ProgressBar

    Behavior on shownValue {
        enabled: !Style.reduceMotion
        NumberAnimation {
            duration: Style.expressiveDurations.expressiveSlowEffects
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Style.expressiveCurves.expressiveSlowEffects
        }
    }

    onAnimatingChanged: {
        if (!animating)
            head1 = tail1 = head2 = tail2 = 0;
    }

    component Segment: Rectangle {
        property real from: 0
        property real to: 0

        x: root.LayoutMirroring.enabled ? root.width - to : from
        width: Math.max(0, to - from)
        height: root.thickness
        anchors.verticalCenter: parent.verticalCenter
        radius: Style.fullRadius(width, height)
        visible: width > 0.5
    }

    // One end of a line: wait, sweep across with the M3 accelerate curve, hold for the rest of the cycle
    component LineEnd: SequentialAnimation {
        id: lineEnd

        property string endProperty
        property int delay
        property int sweep

        PropertyAction {
            target: root
            property: lineEnd.endProperty
            value: 0
        }
        PauseAnimation {
            duration: Style.motionMs(lineEnd.delay)
        }
        NumberAnimation {
            target: root
            property: lineEnd.endProperty
            to: 1
            duration: Style.motionMs(lineEnd.sweep)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.3, 0, 0.8, 0.15, 1, 1]
        }
        PauseAnimation {
            duration: Style.motionMs(root.cycleMs - lineEnd.delay - lineEnd.sweep)
        }
    }

    ParallelAnimation {
        running: root.animating
        loops: Animation.Infinite

        LineEnd {
            endProperty: "head1"
            delay: 0
            sweep: 1000
        }
        LineEnd {
            endProperty: "tail1"
            delay: 250
            sweep: 1000
        }
        LineEnd {
            endProperty: "head2"
            delay: 650
            sweep: 850
        }
        LineEnd {
            endProperty: "tail2"
            delay: 900
            sweep: 850
        }
    }

    // Determinate: active, gap, track, stop dot. Indeterminate without motion: a static full line.
    Segment {
        visible: !root.indeterminate && width > 0.5
        color: root.color
        from: 0
        to: root.shownValue * root.width
    }
    Segment {
        visible: !root.indeterminate && width > 0.5
        color: root.trackColor
        from: root.shownValue > 0 ? root.shownValue * root.width + root.gapSize : 0
        to: root.width
    }
    Segment {
        visible: !root.indeterminate && root.showStopIndicator && root.shownValue < 1
        color: root.color
        from: root.width - root.thickness
        to: root.width
    }
    Segment {
        visible: root.indeterminate && !root.animating
        color: root.color
        from: 0
        to: root.width
    }

    // Indeterminate: track, line 2, track, line 1, track
    Segment {
        visible: root.animating && width > 0.5
        color: root.trackColor
        from: 0
        to: root.l2on ? root.l2s - root.gapSize : root.l1on ? root.l1s - root.gapSize : root.width
    }
    Segment {
        visible: root.l2on
        color: root.color
        from: root.l2s
        to: root.l2e
    }
    Segment {
        visible: root.l1on && root.l2on && width > 0.5
        color: root.trackColor
        from: root.l2e + root.gapSize
        to: root.l1s - root.gapSize
    }
    Segment {
        visible: root.l1on
        color: root.color
        from: root.l1s
        to: root.l1e
    }
    Segment {
        visible: (root.l1on || root.l2on) && width > 0.5
        color: root.trackColor
        from: root.l1on ? root.l1e + root.gapSize : root.l2e + root.gapSize
        to: root.width
    }
}
