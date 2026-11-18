import QtQuick
import qs.DCommon.Common

Item {
    id: root

    property color rippleColor: Style.primary
    property real cornerRadius: 0
    property real topLeftRadius: cornerRadius
    property real topRightRadius: cornerRadius
    property real bottomLeftRadius: cornerRadius
    property real bottomRightRadius: cornerRadius
    property bool enableRipple: Style.enableRippleEffects
    property int animationDuration: Style.motionMs(225)

    // values of Compose material-ripple RippleAnimation, which material3 draws its press ripple with
    readonly property int fadeInDuration: Style.motionMs(75)
    readonly property int fadeOutDuration: Style.motionMs(150)
    readonly property var growCurve: [0.4, 0, 0.2, 1, 1, 1]
    readonly property real startRadiusRatio: 0.3
    readonly property real endRadiusPadding: 10

    property Item fxItem: null
    readonly property bool animating: fxItem?.animating ?? false

    anchors.fill: parent

    // hold keeps the ripple as the pressed state layer until release() is called
    function trigger(x, y, hold = false) {
        if (!enableRipple || Style.reduceMotion)
            return;
        if (!fxItem)
            fxItem = fxComponent.createObject(root);
        fxItem.trigger(x, y, hold);
    }

    function release() {
        fxItem?.release();
    }

    Component {
        id: fxComponent

        Item {
            id: fx
            anchors.fill: parent

            property real pressX: 0
            property real pressY: 0
            property bool held: false
            readonly property real startRadius: Math.max(width, height) * root.startRadiusRatio
            readonly property real endRadius: Math.hypot(width, height) / 2 + root.endRadiusPadding
            readonly property bool animating: held || enter.running || fade.running

            function trigger(x, y, hold) {
                pressX = x;
                pressY = y;
                held = hold;
                fade.stop();
                enter.restart();
            }

            function release() {
                if (!held)
                    return;
                held = false;
                if (enter.running)
                    return;
                fade.restart();
            }

            ParallelAnimation {
                id: enter

                onFinished: {
                    if (!fx.held)
                        fade.restart();
                }

                NumberAnimation {
                    target: rippleFx
                    property: "rippleOpacity"
                    to: Style.stateLayerPressed
                    duration: root.fadeInDuration
                }
                DAnim {
                    target: rippleFx
                    property: "rippleRadius"
                    from: fx.startRadius
                    to: fx.endRadius
                    duration: root.animationDuration
                    easing.bezierCurve: root.growCurve
                }
                NumberAnimation {
                    target: rippleFx
                    property: "rippleCenterX"
                    from: fx.pressX
                    to: fx.width / 2
                    duration: root.animationDuration
                }
                NumberAnimation {
                    target: rippleFx
                    property: "rippleCenterY"
                    from: fx.pressY
                    to: fx.height / 2
                    duration: root.animationDuration
                }
            }

            NumberAnimation {
                id: fade
                target: rippleFx
                property: "rippleOpacity"
                to: 0
                duration: root.fadeOutDuration
            }

            ShaderEffect {
                id: rippleFx
                visible: fx.animating

                property real rippleCenterX: 0
                property real rippleCenterY: 0
                property real rippleRadius: 0
                property real rippleOpacity: 0

                x: Math.max(0, rippleCenterX - rippleRadius)
                y: Math.max(0, rippleCenterY - rippleRadius)
                width: Math.max(0, Math.min(fx.width, rippleCenterX + rippleRadius) - x)
                height: Math.max(0, Math.min(fx.height, rippleCenterY + rippleRadius) - y)

                property real widthPx: width
                property real heightPx: height
                property vector4d cornerRadiiPx: Qt.vector4d(root.topLeftRadius, root.topRightRadius, root.bottomRightRadius, root.bottomLeftRadius)
                property real offsetX: x
                property real offsetY: y
                property real parentWidth: fx.width
                property real parentHeight: fx.height
                property vector4d rippleCol: Qt.vector4d(root.rippleColor.r, root.rippleColor.g, root.rippleColor.b, root.rippleColor.a)

                fragmentShader: Qt.resolvedUrl("../Shaders/qsb/ripple.frag.qsb")
            }
        }
    }
}
