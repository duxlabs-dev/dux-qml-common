import QtQuick
import qs.DCommon.Common

Item {
    id: root

    property real value: 0
    property real actualValue: value
    property bool showActualPlaybackState: false
    property real lineWidth: 2
    property real wavelength: 20
    property real amp: 1.6
    property real phase: 0.0
    property real phaseSpeed: 1.8
    property int tickInterval: 16
    property bool isPlaying: false
    property real currentAmp: isPlaying ? amp : 0
    property color trackColor: Style.withAlpha(Style.surfaceVariant, 0.40)
    property color fillColor: Style.primary
    property color playheadColor: Style.primary
    property color actualProgressColor: Style.onSurface_38
    // A round handle that takes the place of the playhead pill.
    property bool showHandle: false
    property real handleWidth: 0
    property real handleHeight: 0
    property color handleColor: "transparent"
    property real handleGap: 0

    Behavior on currentAmp {
        enabled: !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    ShaderEffect {
        anchors.fill: parent
        blending: true

        readonly property real widthPx: width
        readonly property real heightPx: height
        readonly property real value: root.value
        readonly property real actualValue: root.actualValue
        readonly property real phase: root.phase
        readonly property real ampPx: root.currentAmp
        readonly property real wavelengthPx: root.wavelength
        readonly property real lineWidthPx: root.lineWidth
        readonly property real showActual: root.showActualPlaybackState ? 1.0 : 0.0
        readonly property color fillColor: root.fillColor
        readonly property color trackColor: root.trackColor
        readonly property color playheadColor: root.playheadColor
        readonly property color actualColor: root.actualProgressColor
        readonly property real showHandle: root.showHandle ? 1.0 : 0.0
        readonly property real handleWidthPx: root.handleWidth
        readonly property real handleHeightPx: root.handleHeight
        readonly property color handleColor: root.handleColor
        readonly property real handleGapPx: root.handleGap

        fragmentShader: Qt.resolvedUrl("../Shaders/qsb/wave_progress.frag.qsb")
    }

    signal frameTicked

    Timer {
        interval: root.tickInterval
        repeat: true
        running: !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None && root.visible && root.isPlaying && (root.Window.window?.visible ?? false)
        onTriggered: {
            root.phase = (root.phase + root.phaseSpeed * interval / 1000) % (2 * Math.PI);
            root.frameTicked();
        }
    }
}
