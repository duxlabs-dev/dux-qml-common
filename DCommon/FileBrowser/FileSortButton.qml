pragma ComponentBehavior: Bound

import QtQuick
import qs.DCommon.Common
import qs.DCommon.Widgets

Row {
    id: control

    property string sortKey: "name"
    property bool descending: false
    property bool showLabel: false
    property string tooltipSide: "bottom"

    signal sortKeySelected(string key)
    signal directionToggled

    property var keys: defaultKeys
    readonly property var defaultKeys: [
        {
            "key": "name",
            "icon": "sort_by_alpha",
            "label": I18n.tr("Name", "file browser sort criterion option")
        },
        {
            "key": "size",
            "icon": "straighten",
            "label": I18n.tr("Size", "file browser sort criterion option")
        },
        {
            "key": "mtime",
            "icon": "history",
            "label": I18n.tr("Modified", "file browser sort criterion option")
        },
        {
            "key": "type",
            "icon": "category",
            "label": I18n.tr("Type", "file browser sort criterion option")
        }
    ]
    readonly property var current: keys.find(entry => entry.key === sortKey) ?? keys[0]
    readonly property bool menuOpen: menu.menuVisible

    function openMenu() {
        menu.currentValue = current.label;
        menu.openDropdownMenu();
    }

    spacing: FileBrowserMetrics.navPairGap
    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    ControlSegment {
        id: directionSegment

        joinEnd: true
        width: Math.max(FileBrowserMetrics.navPairSegmentWidth, keyRow.implicitWidth + Style.spacingL * 2)
        tooltipText: control.descending ? I18n.tr("Descending", "file browser sort order option") : I18n.tr("Ascending", "file browser sort order option")
        tooltipSide: control.tooltipSide
        Accessible.name: I18n.tr("Sort By", "file browser sort menu section header")
        Accessible.description: `${control.current.label}, ${tooltipText}`
        onClicked: control.directionToggled()

        Row {
            id: keyRow

            anchors.centerIn: parent
            spacing: Style.spacingS

            DIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: control.current.icon
                size: Style.iconSizeMedium
                color: Style.surfaceText
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: control.showLabel
                text: control.current.label
                color: Style.surfaceText
                font.pixelSize: Style.fontSizeMedium
                font.weight: Style.fontWeightMedium
            }

            DIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: control.descending ? "arrow_downward" : "arrow_upward"
                size: Style.iconSizeSmall
                color: Style.surfaceText
            }
        }
    }

    ControlSegment {
        id: keySegment

        joinStart: true
        width: FileBrowserMetrics.controlSize
        iconName: control.menuOpen ? "keyboard_arrow_up" : "keyboard_arrow_down"
        tooltipText: I18n.tr("Sort By", "file browser sort menu section header")
        tooltipSide: control.tooltipSide
        Accessible.description: control.current.label
        onClicked: control.openMenu()
        Keys.onDownPressed: event => {
            control.openMenu();
            event.accepted = true;
        }

        Rectangle {
            anchors.fill: parent
            visible: control.menuOpen
            topLeftRadius: keySegment.topLeftRadius
            topRightRadius: keySegment.topRightRadius
            bottomLeftRadius: keySegment.bottomLeftRadius
            bottomRightRadius: keySegment.bottomRightRadius
            color: Style.withAlpha(Style.surfaceText, Style.stateLayerPressed)
        }

        DDropdown {
            id: menu

            showTrigger: false
            popupAnchorItem: control
            focusReturnTarget: keySegment
            alignPopupRight: !I18n.isRtl
            popupWidth: FileBrowserMetrics.menuWidth
            options: control.keys.map(entry => entry.label)
            optionIcons: control.keys.map(entry => entry.icon)
            onValueChanged: value => {
                const index = options.indexOf(value);
                if (index < 0)
                    return;
                control.sortKeySelected(control.keys[index].key);
            }
        }
    }
}
