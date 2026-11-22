import QtQuick
import qs.DCommon.Common

Item {
    id: root

    property real size: 48
    property bool contained: false
    property color containerColor: Style.primaryContainer
    property color color: contained ? Style.onPrimaryContainer : Style.primary
    property bool running: visible

    readonly property var shapes: ["softBurst", "cookie9", "pentagon", "pill", "sunny", "cookie4", "oval"]
    readonly property real activeRatio: 38 / 48
    readonly property int morphInterval: 650
    readonly property int rotationDuration: 4666
    readonly property real dampingRatio: 0.6
    readonly property real stiffness: 200
    readonly property real visibilityThreshold: 0.1
    readonly property real decay: dampingRatio * Math.sqrt(stiffness)
    readonly property real frequency: Math.sqrt(stiffness * (1 - dampingRatio * dampingRatio))
    readonly property real settleTime: Math.log(Math.hypot(1, decay / frequency) / visibilityThreshold) / decay

    property real elapsed: 0
    readonly property int step: Math.floor(elapsed / morphInterval)
    readonly property real morph: springAt((elapsed - step * morphInterval) / 1000)

    implicitWidth: size
    implicitHeight: size

    onRunningChanged: {
        if (!running)
            elapsed = 0;
    }

    function springAt(seconds) {
        if (seconds >= settleTime)
            return 1;
        return 1 - Math.exp(-decay * seconds) * (Math.cos(frequency * seconds) + decay / frequency * Math.sin(frequency * seconds));
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(root.width, root.height)
        height: width
        radius: Style.fullRadius(width, height)
        color: root.containerColor
        visible: root.contained
    }

    DMorphShape {
        anchors.centerIn: parent
        width: Math.min(root.width, root.height)
        height: width
        shapes: root.shapes
        from: root.shapes[root.step % root.shapes.length]
        to: root.shapes[(root.step + 1) % root.shapes.length]
        progress: root.morph
        angle: (root.morph * 90 + (root.step + 1) * 90 + root.elapsed % root.rotationDuration / root.rotationDuration * 360) * Math.PI / 180
        fill: root.activeRatio
        color: root.color
        respectThemeShape: false
    }

    FrameAnimation {
        running: root.running
        onTriggered: root.elapsed += frameTime * 1000
    }
}
