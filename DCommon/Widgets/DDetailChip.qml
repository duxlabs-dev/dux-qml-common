import QtQuick
import qs.DCommon.Common

Rectangle {
    id: root

    property string label: ""
    property string value: ""
    property color valueColor: Style.surfaceText
    property real maximumWidth: -1
    property alias leading: leadingRow.data

    implicitWidth: content.implicitWidth + Style.spacingM * 2
    implicitHeight: Style.buttonHeightXS
    radius: Style.cornerRadiusS
    color: Style.floatingWindowFieldColor
    border.width: Style.outlineWidth
    border.color: Style.floatingWindowFieldBorderColor
    Accessible.role: Accessible.StaticText
    Accessible.name: label !== "" ? label + ": " + value : value

    Row {
        id: content
        anchors.centerIn: parent
        spacing: Style.spacingXS

        Row {
            id: leadingRow
            visible: children.length > 0
            spacing: Style.spacingXS
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            id: labelText
            visible: root.label !== ""
            text: root.label + ":"
            font.pixelSize: Style.fontSizeSmall
            color: Style.surfaceVariantText
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            readonly property real cap: {
                if (root.maximumWidth <= 0)
                    return -1;
                let used = Style.spacingM * 2;
                if (leadingRow.children.length > 0)
                    used += leadingRow.width + content.spacing;
                if (root.label !== "")
                    used += labelText.implicitWidth + content.spacing;
                return Math.max(0, root.maximumWidth - used);
            }

            text: root.value
            width: cap < 0 ? implicitWidth : Math.min(implicitWidth, cap)
            wrapMode: Text.NoWrap
            font.pixelSize: Style.fontSizeSmall
            font.weight: Style.fontWeightMedium
            color: root.valueColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
