import QtQuick
import QtQuick.Controls
import QtQuick.Window
import qs.DCommon.Common
import qs.DCommon.Widgets
import "ScrollConstants.js" as Scroll
import "Reveal.js" as Reveal
import "../Common/WheelInput.js" as WheelInput

Flickable {
    id: flickable

    property alias verticalScrollBar: vbar
    property bool showScrollBar: true
    property bool fadeEdges: true
    property real fadeLength: Style.spacingXL
    property real fadeTopInset: 0
    property real fadeBottomInset: 0
    property real fadeSideInset: 0
    readonly property real revealInsetTop: fadeEdges ? fadeTopInset + fadeLength : 0
    readonly property real revealInsetBottom: fadeEdges ? fadeBottomInset + fadeLength : 0

    function revealRange(top, bottom) {
        contentY = Reveal.contentYFor(flickable, top, bottom, revealInsetTop, revealInsetBottom);
    }
    property real mouseWheelSpeed: Scroll.mouseWheelSpeed
    property bool wheelEnabled: true
    property real momentumVelocity: 0
    property bool isMomentumActive: false
    readonly property bool windowVisible: flickable.Window.window?.visible ?? false
    property real friction: Scroll.friction
    property bool _scrollBarActive: false

    flickDeceleration: Scroll.flickDeceleration
    maximumFlickVelocity: Scroll.maximumFlickVelocity
    boundsBehavior: Flickable.StopAtBounds
    boundsMovement: Flickable.FollowBoundsBehavior
    pressDelay: 0
    flickableDirection: Flickable.VerticalFlick

    WheelHandler {
        id: wheelHandler
        enabled: flickable.wheelEnabled

        property real touchpadSpeed: Scroll.touchpadSpeed
        property real momentumRetention: Scroll.momentumRetention
        property real lastWheelTime: 0
        property real momentum: 0
        property var velocitySamples: []
        property bool sessionUsedMouseWheel: false

        function startMomentum() {
            if (!flickable.visible || !flickable.Window.window?.visible)
                return;
            flickable.isMomentumActive = true;
            momentumAnim.running = true;
        }

        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

        onWheel: event => handleWheel(event)

        function handleWheel(event) {
            vbar._scrollBarActive = true;
            vbar.hideTimer.restart();

            const currentTime = Date.now();
            const timeDelta = currentTime - lastWheelTime;
            lastWheelTime = currentTime;

            const kind = WheelInput.verticalKind(event);
            const deltaY = event.angleDelta.y;

            if (kind === WheelInput.Kind.wheel) {
                sessionUsedMouseWheel = true;
                momentumAnim.running = false;
                flickable.isMomentumActive = false;
                velocitySamples = [];
                momentum = 0;
                flickable.momentumVelocity = 0;

                const lines = Math.round(Math.abs(deltaY) / 120);
                const scrollAmount = (deltaY > 0 ? -lines : lines) * flickable.mouseWheelSpeed;
                let newY = flickable.contentY + scrollAmount;
                newY = Math.max(0, Math.min(flickable.contentHeight - flickable.height, newY));

                if (flickable.flicking) {
                    flickable.cancelFlick();
                }

                flickable.contentY = newY;
            } else if (kind === WheelInput.Kind.highResWheel) {
                sessionUsedMouseWheel = true;
                momentumAnim.running = false;
                flickable.isMomentumActive = false;
                velocitySamples = [];
                momentum = 0;
                flickable.momentumVelocity = 0;

                let delta = deltaY / 8 * touchpadSpeed;
                let newY = flickable.contentY - delta;
                newY = Math.max(0, Math.min(flickable.contentHeight - flickable.height, newY));

                if (flickable.flicking) {
                    flickable.cancelFlick();
                }

                flickable.contentY = newY;
            } else if (kind === WheelInput.Kind.touchpad) {
                sessionUsedMouseWheel = false;
                momentumAnim.running = false;
                flickable.isMomentumActive = false;

                let delta = event.pixelDelta.y * touchpadSpeed;

                velocitySamples.push({
                    "delta": delta,
                    "time": currentTime
                });
                velocitySamples = velocitySamples.filter(s => currentTime - s.time < Scroll.velocitySampleWindowMs);

                if (velocitySamples.length > 1) {
                    const totalDelta = velocitySamples.reduce((sum, s) => sum + s.delta, 0);
                    const timeSpan = currentTime - velocitySamples[0].time;
                    if (timeSpan > 0) {
                        flickable.momentumVelocity = Math.max(-Scroll.maxMomentumVelocity, Math.min(Scroll.maxMomentumVelocity, totalDelta / timeSpan * 1000));
                    }
                }

                if (timeDelta < Scroll.momentumTimeThreshold) {
                    momentum = momentum * momentumRetention + delta * Scroll.momentumDeltaFactor;
                    delta += momentum;
                } else {
                    momentum = 0;
                }

                let newY = flickable.contentY - delta;
                newY = Math.max(0, Math.min(flickable.contentHeight - flickable.height, newY));

                if (flickable.flicking) {
                    flickable.cancelFlick();
                }

                flickable.contentY = newY;
            }

            event.accepted = true;
        }

        onActiveChanged: {
            if (!active)
                release();
        }

        function release() {
            if (!sessionUsedMouseWheel && Math.abs(flickable.momentumVelocity) >= Scroll.minMomentumVelocity) {
                startMomentum();
            } else {
                velocitySamples = [];
                flickable.momentumVelocity = 0;
            }
        }
    }

    onMovementStarted: {
        vbar._scrollBarActive = true;
        vbar.hideTimer.stop();
    }
    onMovementEnded: vbar.hideTimer.restart()

    function forwardWheel(event) {
        if (!wheelEnabled)
            return;
        wheelHandler.handleWheel(event);
    }

    function forwardWheelEnd() {
        wheelHandler.release();
    }

    function stopMomentum() {
        cancelFlick();
        momentumAnim.running = false;
        isMomentumActive = false;
        momentumVelocity = 0;
        wheelHandler.momentum = 0;
        wheelHandler.velocitySamples = [];
    }

    onVisibleChanged: {
        if (!visible)
            stopMomentum();
    }

    onWindowVisibleChanged: {
        if (!windowVisible)
            stopMomentum();
    }

    FrameAnimation {
        id: momentumAnim
        running: false

        onTriggered: {
            const dt = frameTime;
            const newY = flickable.contentY - flickable.momentumVelocity * dt;
            const maxY = Math.max(0, flickable.contentHeight - flickable.height);

            if (newY < 0 || newY > maxY) {
                flickable.contentY = newY < 0 ? 0 : maxY;
                running = false;
                flickable.isMomentumActive = false;
                flickable.momentumVelocity = 0;
                return;
            }

            flickable.contentY = newY;
            flickable.momentumVelocity *= Math.pow(flickable.friction, dt / 0.016);

            if (Math.abs(flickable.momentumVelocity) < Scroll.momentumStopThreshold) {
                running = false;
                flickable.isMomentumActive = false;
                flickable.momentumVelocity = 0;
            }
        }
    }

    Loader {
        parent: flickable
        anchors.fill: parent
        anchors.topMargin: flickable.fadeTopInset
        anchors.bottomMargin: flickable.fadeBottomInset
        anchors.leftMargin: flickable.fadeSideInset
        anchors.rightMargin: flickable.fadeSideInset
        z: 1
        active: flickable.fadeEdges && flickable.contentHeight > flickable.height + 1
        sourceComponent: DEdgeFade {
            target: flickable
            length: flickable.fadeLength
        }
    }

    ScrollBar.vertical: DScrollbar {
        id: vbar
        z: 2
        targetFlickable: flickable
        allowed: flickable.showScrollBar
    }
}
