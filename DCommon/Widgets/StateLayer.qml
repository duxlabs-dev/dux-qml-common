import QtQuick
import QtQuick.Templates as T
import qs.DCommon.Common

MouseArea {
    id: root

    property bool disabled: false
    property bool hovered: control ? control.hovered : containsMouse
    // visualFocus is keyboard-only, so pointer focus never tints
    property bool focused: control ? control.visualFocus : false
    property T.AbstractButton control: null
    property color stateColor: Style.surfaceText
    property real cornerRadius: parent && parent.radius !== undefined ? parent.radius : Style.cornerRadius
    property real topLeftRadius: parent && parent.topLeftRadius !== undefined ? parent.topLeftRadius : cornerRadius
    property real topRightRadius: parent && parent.topRightRadius !== undefined ? parent.topRightRadius : cornerRadius
    property real bottomLeftRadius: parent && parent.bottomLeftRadius !== undefined ? parent.bottomLeftRadius : cornerRadius
    property real bottomRightRadius: parent && parent.bottomRightRadius !== undefined ? parent.bottomRightRadius : cornerRadius
    property var tooltipText: null
    property bool tooltipMultiline: false
    property string tooltipSide: "bottom"
    property bool enableRipple: Style.enableRippleEffects
    property int transitionDuration: Style.expressiveDurations.expressiveFastEffects
    property var transitionCurve: Style.expressiveCurves.expressiveFastEffects

    readonly property bool isPressed: control ? control.down : pressed
    // the held ripple is the pressed layer whenever it can draw
    readonly property bool rippleDrawsPress: enableRipple && !Style.reduceMotion
    readonly property real stateOpacity: {
        if (disabled)
            return 0;
        if (isPressed && !rippleDrawsPress)
            return Style.stateLayerPressed;
        if (focused)
            return Style.stateLayerFocus;
        if (hovered)
            return Style.stateLayerHover;
        return 0;
    }
    readonly property bool controlPressed: control ? control.pressed : false

    property Rectangle _stateRect: null
    property DRipple _ripple: null
    property bool _completed: false

    anchors.fill: parent
    cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
    hoverEnabled: true
    acceptedButtons: control ? Qt.NoButton : Qt.LeftButton

    readonly property bool controlFocused: control ? control.visualFocus : false

    function showTooltip() {
        presentTooltip(0);
    }

    function presentTooltip(delay) {
        if (!tooltipText)
            return;
        tooltipLoader.active = true;
        const host = tooltipLoader.item;
        host?.present(delay);
        if (!host?.shown)
            tooltipLoader.active = false;
    }

    function pressRipple(x, y) {
        if (disabled || !rippleDrawsPress)
            return;
        if (!_ripple)
            _ripple = rippleComponent.createObject(root);
        _ripple.trigger(x, y, true);
    }

    onPressed: mouse => pressRipple(mouse.x, mouse.y)
    onReleased: _ripple?.release()
    onCanceled: _ripple?.release()

    onControlPressedChanged: {
        if (!controlPressed) {
            _ripple?.release();
            return;
        }
        const point = mapFromItem(control, control.pressX, control.pressY);
        pressRipple(point.x, point.y);
    }

    onStateOpacityChanged: {
        if (stateOpacity > 0 && !_stateRect)
            _stateRect = stateRectComponent.createObject(root);
    }

    Component.onCompleted: _completed = true

    // z -1 keeps both layers under children declared at the use site, whenever they get created
    Component {
        id: stateRectComponent

        Rectangle {
            // 0 until _stateRect is assigned, so a first tint after completion fades in like every later one
            property real stateAlpha: root._stateRect ? root.stateOpacity : 0

            anchors.fill: parent
            z: -1
            radius: root.cornerRadius
            topLeftRadius: root.topLeftRadius
            topRightRadius: root.topRightRadius
            bottomLeftRadius: root.bottomLeftRadius
            bottomRightRadius: root.bottomRightRadius
            color: Style.withAlpha(root.stateColor, stateAlpha)

            Behavior on stateAlpha {
                enabled: root._completed && !Style.reduceMotion
                DAnim {
                    duration: root.transitionDuration
                    easing.bezierCurve: root.transitionCurve
                }
            }
        }
    }

    Component {
        id: rippleComponent

        DRipple {
            anchors.fill: parent
            z: -1
            rippleColor: root.stateColor
            cornerRadius: root.cornerRadius
            topLeftRadius: root.topLeftRadius
            topRightRadius: root.topRightRadius
            bottomLeftRadius: root.bottomLeftRadius
            bottomRightRadius: root.bottomRightRadius
            enableRipple: root.enableRipple
        }
    }

    onEntered: presentTooltip(Style.tooltipDelay)

    onExited: {
        if (!controlFocused)
            tooltipLoader.item?.dismiss();
    }

    onControlFocusedChanged: {
        if (controlFocused) {
            presentTooltip(0);
            return;
        }
        if (!containsMouse)
            tooltipLoader.item?.dismiss();
    }

    Loader {
        id: tooltipLoader
        active: false
        sourceComponent: DTooltipHost {
            text: root.tooltipText
            multiline: root.tooltipMultiline
            target: root
            side: root.tooltipSide
            enabled: !root.disabled

            readonly property bool idle: !shown && !presenting
            onIdleChanged: {
                if (!idle) {
                    releaseTimer.stop();
                    return;
                }
                releaseTimer.restart();
            }

            // idle turns true while the tooltip is still inside its own close() call, so wait before destroying it
            Timer {
                id: releaseTimer
                interval: Style.shorterDuration
                onTriggered: tooltipLoader.active = false
            }
        }
    }
}
