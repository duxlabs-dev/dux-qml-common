import QtQuick
import QtQuick.Window
import Quickshell
import qs.DCommon.Common

Row {
    id: root

    property var model: []
    property int currentIndex: -1
    property string selectionMode: "single"
    property bool arrowKeysSelect: true
    property bool multiSelect: selectionMode === "multi"
    property var initialSelection: []
    property var currentSelection: initialSelection
    property bool checkEnabled: true
    property color selectedColor: Style.buttonBg
    property color selectedContentColor: Style.buttonText
    property color unselectedColor: Style.foregroundColor(Style.secondaryContainer, !root.usePopupTransparency)
    property color unselectedContentColor: Style.onSecondaryContainer
    property bool iconOnly: false
    property bool labelOnlySelected: false
    property string size: "medium"
    property int buttonHeight: size === "small" ? Style.buttonHeightXS : Style.buttonHeightS
    property bool compactLayout: root.Window.window ? root.Window.window.width < Style.smallBreakpoint : false
    property int minButtonWidth: size === "small" ? (compactLayout ? 40 : 56) : (compactLayout ? 44 : 64)
    property int buttonPadding: (size === "small" || compactLayout) ? Style.spacingM : Style.spacingL
    property int checkIconSize: Style.iconSizeSmall
    property int textSize: size === "small" ? Style.fontSizeSmall : Style.fontSizeMedium
    property bool userInteracted: false
    property bool interactionStarted: false
    property bool usePopupTransparency: !Style.isFloatingWindow(root)
    property real maximumWidth: -1
    property bool fillWidth: false
    readonly property real _segmentCap: {
        const count = model?.length ?? 0;
        if (maximumWidth <= 0 || count === 0)
            return -1;
        return (maximumWidth - spacing * (count - 1)) / count - Style.spacingXS;
    }
    readonly property real outerRadius: Style.pillControls ? Style.fullRadius(buttonHeight, buttonHeight) : Style.cornerRadiusL
    // Separate whole buttons when selection no longer changes their shape.
    readonly property real innerRadius: Style.pillControls ? Math.min(Style.innerRadius("s"), outerRadius) : outerRadius
    readonly property real pressedInnerRadius: Math.min(Style.innerRadius("xs"), outerRadius)

    signal selectionChanged(int index, bool selected)
    signal animationCompleted

    spacing: Style.pillControls ? Style.groupedListGap : Style.spacingXS
    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    Timer {
        id: animationTimer
        interval: Style.shortDuration
        onTriggered: {
            root.userInteracted = false;
            root.animationCompleted();
        }
    }

    property int focusedIndex: currentIndex
    readonly property int focusIndex: Math.max(0, Math.min(focusedIndex, (model?.length ?? 0) - 1))
    onCurrentIndexChanged: {
        if (arrowKeysSelect || !repeater.itemAt(focusIndex)?.activeFocus)
            focusedIndex = currentIndex;
    }

    function requestFocus(backwards, reason) {
        repeater.itemAt(focusIndex)?.forceActiveFocus(reason ?? (backwards ? Qt.BacktabFocusReason : Qt.TabFocusReason));
    }

    Keys.onPressed: event => {
        if (!enabled || (event.modifiers & ~Qt.KeypadModifier) !== Qt.NoModifier || (model?.length ?? 0) === 0)
            return;
        const count = model.length;
        const forwardKey = I18n.isRtl ? Qt.Key_Left : Qt.Key_Right;
        const backwardKey = I18n.isRtl ? Qt.Key_Right : Qt.Key_Left;
        if (event.key === forwardKey) {
            focusSegment((focusIndex + 1) % count);
            event.accepted = true;
            return;
        }
        if (event.key === backwardKey) {
            focusSegment((focusIndex - 1 + count) % count);
            event.accepted = true;
        }
    }

    function focusSegment(index) {
        focusedIndex = index;
        repeater.itemAt(index)?.forceActiveFocus(Qt.TabFocusReason);
        if (!multiSelect && arrowKeysSelect)
            selectItem(index);
    }

    function isSelected(index) {
        if (multiSelect)
            return repeater.itemAt(index)?.selected || false;
        return index === currentIndex;
    }

    function selectItem(index) {
        interactionStarted = true;
        userInteracted = true;
        if (multiSelect) {
            const modelValue = model[index];
            let newSelection = [...currentSelection];
            const isCurrentlySelected = newSelection.includes(modelValue);

            if (isCurrentlySelected) {
                newSelection = newSelection.filter(item => item !== modelValue);
            } else {
                newSelection.push(modelValue);
            }

            currentSelection = newSelection;
            selectionChanged(index, !isCurrentlySelected);
            animationTimer.restart();
        } else {
            const oldIndex = currentIndex;
            selectionChanged(index, true);
            if (oldIndex !== index && oldIndex >= 0) {
                selectionChanged(oldIndex, false);
            }
            animationTimer.restart();
        }
    }

    Repeater {
        id: repeater
        model: ScriptModel {
            values: root.model
        }

        delegate: StyledButton {
            id: segment

            focusPolicy: activeFocus || index === root.focusIndex ? Qt.StrongFocus : Qt.ClickFocus
            onActiveFocusChanged: {
                if (activeFocus)
                    root.focusedIndex = index;
                else if (!root.arrowKeysSelect)
                    root.focusedIndex = root.currentIndex;
            }
            onClicked: root.selectItem(index)
            onPressedChanged: {
                if (pressed)
                    root.interactionStarted = true;
            }

            Accessible.role: root.multiSelect ? Accessible.CheckBox : root.arrowKeysSelect ? Accessible.RadioButton : Accessible.Button
            Accessible.name: buttonText.text
            checkable: true
            checked: selected
            property bool selected: multiSelect ? root.currentSelection.includes(modelData) : (index === root.currentIndex)
            property bool visualFirst: index === 0
            property bool visualLast: index === repeater.count - 1
            property bool prevSelected: index > 0 ? root.isSelected(index - 1) : false
            property bool nextSelected: index < repeater.count - 1 ? root.isSelected(index + 1) : false
            readonly property real joinRadius: !Style.shapeMorph ? root.innerRadius : (pressed ? root.pressedInnerRadius : (selected ? root.outerRadius : root.innerRadius))
            readonly property real leftRadius: visualFirst ? root.outerRadius : joinRadius
            readonly property real rightRadius: visualLast ? root.outerRadius : joinRadius
            readonly property color contentColor: !root.enabled ? Style.onSurface_38 : (selected ? root.selectedContentColor : root.unselectedContentColor)

            readonly property real contentNaturalWidth: (checkIcon.visible ? checkIcon.width + contentRow.spacing : 0) + (optionIcon.visible ? optionIcon.width + (buttonText.visible ? contentRow.spacing : 0) : 0) + (buttonText.visible ? buttonText.implicitWidth : 0)

            readonly property real baseWidth: {
                if (root.fillWidth)
                    return Math.max(0, (root.width - root.spacing * (repeater.count - 1)) / Math.max(1, repeater.count));
                const natural = Math.max(contentNaturalWidth + root.buttonPadding * 2, root.minButtonWidth);
                return root._segmentCap > 0 ? Math.min(natural, Math.max(root._segmentCap, root.minButtonWidth)) : natural;
            }

            width: baseWidth
            height: root.buttonHeight

            color: !root.enabled ? Style.onSurface_10 : (selected ? root.selectedColor : root.unselectedColor)
            border.color: "transparent"
            border.width: 0

            topLeftRadius: mirrored ? rightRadius : leftRadius
            bottomLeftRadius: mirrored ? rightRadius : leftRadius
            topRightRadius: mirrored ? leftRadius : rightRadius
            bottomRightRadius: mirrored ? leftRadius : rightRadius

            Behavior on topLeftRadius {
                enabled: root.interactionStarted && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DAnim {
                    duration: Style.expressiveDurations.expressiveFastSpatial
                    easing.bezierCurve: Style.expressiveCurves.standard
                }
            }

            Behavior on topRightRadius {
                enabled: root.interactionStarted && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DAnim {
                    duration: Style.expressiveDurations.expressiveFastSpatial
                    easing.bezierCurve: Style.expressiveCurves.standard
                }
            }

            Behavior on bottomLeftRadius {
                enabled: root.interactionStarted && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DAnim {
                    duration: Style.expressiveDurations.expressiveFastSpatial
                    easing.bezierCurve: Style.expressiveCurves.standard
                }
            }

            Behavior on bottomRightRadius {
                enabled: root.interactionStarted && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DAnim {
                    duration: Style.expressiveDurations.expressiveFastSpatial
                    easing.bezierCurve: Style.expressiveCurves.standard
                }
            }

            Behavior on color {
                enabled: root.userInteracted && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                DColorAnim {
                    duration: Style.expressiveDurations.expressiveEffects
                    easing.bezierCurve: Style.expressiveCurves.expressiveEffects
                }
            }

            StateLayer {
                id: stateLayer
                control: segment
                enabled: root.enabled
                disabled: !root.enabled
                stateColor: segment.contentColor
                transitionDuration: Style.expressiveDurations.expressiveEffects
                transitionCurve: Style.expressiveCurves.expressiveEffects
                tooltipText: (typeof modelData === "object" && modelData.tooltip) ? modelData.tooltip : (buttonText.visible ? "" : buttonText.text)
            }

            FocusRing {
                radius: Math.min(Style.fullRadius(width, height), root.outerRadius + Style.focusRingOffset)
                visible: segment.visualFocus
            }

            Item {
                id: contentItem
                anchors.centerIn: parent
                implicitWidth: contentRow.implicitWidth
                implicitHeight: contentRow.implicitHeight

                Row {
                    id: contentRow
                    spacing: Style.spacingS

                    DIcon {
                        id: checkIcon
                        name: "check"
                        size: root.checkIconSize
                        color: segment.contentColor
                        visible: root.checkEnabled && !root.iconOnly && segment.selected
                        opacity: segment.selected ? 1 : 0
                        scale: segment.selected ? 1 : Style.iconEnterScale
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on opacity {
                            enabled: root.userInteracted && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                            DAnim {
                                duration: Style.expressiveDurations.expressiveEffects
                                easing.bezierCurve: Style.expressiveCurves.expressiveEffects
                            }
                        }

                        Behavior on scale {
                            enabled: root.userInteracted && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
                            DAnim {
                                duration: Style.expressiveDurations.expressiveFastSpatial
                                easing.bezierCurve: Style.expressiveCurves.expressiveFastSpatial
                            }
                        }
                    }

                    DIcon {
                        id: optionIcon
                        name: typeof modelData === "object" ? modelData.icon || "" : ""
                        size: Style.iconSize
                        color: segment.contentColor
                        filled: segment.selected
                        visible: name !== ""
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        id: buttonText
                        visible: {
                            if (!optionIcon.visible)
                                return true;
                            if (root.labelOnlySelected)
                                return segment.selected;
                            return !root.iconOnly;
                        }

                        readonly property real capAvailable: {
                            if (root._segmentCap <= 0)
                                return -1;
                            const cap = Math.max(root._segmentCap, root.minButtonWidth);
                            return Math.max(0, cap - root.buttonPadding * 2 - (checkIcon.visible ? checkIcon.width + contentRow.spacing : 0) - (optionIcon.visible ? optionIcon.width + contentRow.spacing : 0));
                        }

                        text: typeof modelData === "string" ? modelData : modelData.text || ""
                        font.pixelSize: root.textSize
                        font.weight: Style.fontWeightMedium
                        color: segment.contentColor
                        anchors.verticalCenter: parent.verticalCenter
                        width: capAvailable < 0 ? implicitWidth : Math.min(implicitWidth, capAvailable)
                        wrapMode: Text.NoWrap
                    }
                }
            }
        }
    }
}
