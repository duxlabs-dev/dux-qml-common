import QtQuick
import qs.DCommon.Common

Item {
    id: root

    property alias name: icon.text
    property alias size: icon.font.pixelSize
    property alias color: icon.color
    property bool filled: false
    property real fill: filled ? 1.0 : 0.0
    property int grade: Style.isLightMode ? 0 : -25
    property int weight: filled ? 500 : 400
    property bool smoothTransform: false

    property real _shownFill: fill
    property int _shownWeight: weight
    property bool _ready: false
    property Loader _incoming: null

    implicitWidth: Math.round(size)
    implicitHeight: Math.round(size)

    onFillChanged: retarget()
    onWeightChanged: retarget()

    function retarget() {
        if (!_ready || !visible) {
            settle();
            return;
        }
        if (fill === _shownFill && weight === _shownWeight) {
            settle();
            return;
        }
        if (!_incoming)
            _incoming = incomingComponent.createObject(root);
        _incoming.fadeIn();
    }

    function settle() {
        _incoming?.stopFade();
        _shownFill = fill;
        _shownWeight = weight;
        if (!_incoming)
            return;
        icon.opacity = 1;
        _incoming.active = false;
    }

    Component.onCompleted: {
        _shownFill = fill;
        _shownWeight = weight;
        _ready = true;
    }

    DIconGlyph {
        id: icon

        anchors.fill: parent

        font.pixelSize: Math.round(Style.fontSizeMedium)
        font.weight: root._shownWeight
        color: Style.surfaceText
        renderType: root.smoothTransform ? Text.QtRendering : Text.NativeRendering

        font.variableAxes: {
            "FILL": root._shownFill,
            "GRAD": root.grade,
            "opsz": 24,
            "wght": root._shownWeight
        }
    }

    Component {
        id: incomingComponent

        Loader {
            id: incoming

            function fadeIn() {
                active = true;
                crossfade.restart();
            }

            function stopFade() {
                crossfade.stop();
            }

            anchors.fill: parent
            active: false
            opacity: 0

            sourceComponent: DIconGlyph {
                text: icon.text
                font.pixelSize: icon.font.pixelSize
                font.weight: root.weight
                color: icon.color
                renderType: icon.renderType

                font.variableAxes: {
                    "FILL": root.fill,
                    "GRAD": root.grade,
                    "opsz": 24,
                    "wght": root.weight
                }
            }

            SequentialAnimation {
                id: crossfade

                NumberAnimation {
                    target: incoming
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Style.expressiveDurations.expressiveFastEffects / 2
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Style.expressiveCurves.expressiveFastEffects
                }
                NumberAnimation {
                    target: icon
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Style.expressiveDurations.expressiveFastEffects / 2
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Style.expressiveCurves.expressiveFastEffects
                }

                onFinished: root.settle()
            }
        }
    }
}
