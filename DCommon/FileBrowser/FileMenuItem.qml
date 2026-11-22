pragma ComponentBehavior: Bound

import QtQuick
import qs.DCommon.Common
import qs.DCommon.Widgets

StyledButton {
    id: root

    property string iconName: ""
    property string appIcon: ""
    property bool submenu: false
    property bool danger: false
    property bool highlighted: false
    property string shortcutText: ""

    readonly property bool hasLeadingIcon: appIcon !== "" || iconName !== ""

    readonly property color contentColor: {
        if (!enabled)
            return Style.onSurface_38;
        return danger ? Style.error : Style.surfaceText;
    }
    readonly property color iconColor: {
        if (!enabled)
            return Style.onSurface_38;
        return danger ? Style.error : Style.surfaceVariantText;
    }

    width: parent?.width ?? 0
    implicitHeight: Style.menuRowHeight
    radius: Style.cornerRadiusS
    color: "transparent"

    StateLayer {
        control: root
        disabled: !root.enabled
        hovered: root.hovered || root.highlighted
        stateColor: root.contentColor
    }

    FocusRing {
        visible: root.visualFocus
        anchors.margins: Style.focusRingWidth / 2
        radius: Math.max(0, root.radius - Style.focusRingWidth / 2)
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Style.spacingM
        anchors.rightMargin: Style.spacingM
        spacing: Style.spacingM

        Loader {
            anchors.verticalCenter: parent.verticalCenter
            width: Style.menuItemIconSize
            height: Style.menuItemIconSize
            active: root.appIcon !== ""
            visible: active
            sourceComponent: AppIconRenderer {
                iconValue: root.appIcon
                iconSize: Style.menuItemIconSize
                iconColor: root.iconColor
                fallbackText: root.text.charAt(0).toUpperCase()
            }
        }

        DIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.appIcon === "" && root.iconName !== ""
            name: root.iconName
            size: Style.menuItemIconSize
            color: root.iconColor
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - (root.hasLeadingIcon ? Style.menuItemIconSize + parent.spacing : 0) - (root.submenu || root.checked ? Style.menuItemIconSize + Style.spacingM : 0) - (hint.visible ? hint.implicitWidth + Style.spacingM : 0)
            text: root.text
            color: root.contentColor
            font.pixelSize: Style.fontSizeMedium
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }
    }

    StyledText {
        id: hint

        anchors.right: parent.right
        anchors.rightMargin: Style.spacingM + (root.submenu || root.checked ? Style.menuItemIconSize + Style.spacingM : 0)
        anchors.verticalCenter: parent.verticalCenter
        visible: root.shortcutText !== ""
        text: root.shortcutText
        color: root.iconColor
        font.pixelSize: Style.fontSizeSmall
        wrapMode: Text.NoWrap
    }

    DIcon {
        anchors.right: parent.right
        anchors.rightMargin: Style.spacingM
        anchors.verticalCenter: parent.verticalCenter
        visible: root.submenu || root.checked
        name: root.submenu ? "chevron_right" : "check"
        size: Style.menuItemIconSize
        color: root.submenu ? Style.surfaceVariantText : Style.primary
    }
}
