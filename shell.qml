//@ pragma UseQApplication

pragma ComponentBehavior: Bound

import QtQuick
import qs.DCommon.Widgets
import Quickshell
import qs.Common
import qs.Common as App
import qs.Services as AppServices
import qs.DCommon.Common
import qs.DCommon.Common as DC
import qs.DCommon.FileBrowser
import qs.Services

ShellRoot {
    id: root

    readonly property var log: Log.scoped("Gallery")

    Component.onCompleted: {
        DC.Style.theme = App.Theme;
        DC.Style.settings = App.SettingsData;
        DC.I18n.backend = App.I18n;
        DC.Paths.backend = App.Paths;
        DC.Log.backend = AppServices.Log;
        DC.Host.session = AppServices.SessionService;
        DC.Host.cache = App.CacheData;
        DC.Host.files = AppServices.FilesBackend;
    }

    FloatingWindow {
        id: window

        readonly property var widthPresets: [
            {
                "label": "360",
                "value": 360
            },
            {
                "label": "480",
                "value": 480
            },
            {
                "label": "768",
                "value": 768
            },
            {
                "label": "Wide",
                "value": 1000
            }
        ]

        property int widthPresetIndex: 3

        readonly property int presetWidth: widthPresets[widthPresetIndex].value
        readonly property string layoutClass: width < Style.smallBreakpoint ? "small" : width < Style.mediumBreakpoint ? "medium" : "large"

        title: "DCommon Gallery"
        implicitWidth: presetWidth
        implicitHeight: 800
        minimumSize: Qt.size(360, 400)
        color: Theme.surface
        visible: true

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StyledRect {
                id: inspector

                width: parent.width
                height: inspectorContent.implicitHeight + Theme.spacingM * 2
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                Flow {
                    id: inspectorContent

                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingM

                    DButton {
                        text: I18n.tr("Text fields")
                        onClicked: galleryFlickable.contentY = widgetExamples.y
                    }

                    Column {
                        width: Theme.fieldDefaultWidth
                        spacing: Theme.spacingXS

                        StyledText {
                            text: I18n.tr("Radius scale")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        DSlider {
                            width: parent.width
                            Accessible.name: I18n.tr("Radius scale")
                            value: Theme.radiusStrength
                            minimum: 0
                            maximum: 100
                            onSliderValueChanged: value => Theme.radiusStrength = value
                        }
                    }

                    Column {
                        spacing: Theme.spacingXS

                        StyledText {
                            text: "Window width"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        DButtonGroup {
                            model: window.widthPresets.map(p => p.label)
                            currentIndex: window.widthPresetIndex
                            onSelectionChanged: (index, selected) => {
                                if (selected)
                                    window.widthPresetIndex = index;
                            }
                        }
                    }

                    Column {
                        spacing: Theme.spacingXS

                        StyledText {
                            text: "Window"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            text: `${window.width}x${window.height} · ${window.layoutClass}`
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }
                    }
                }
            }

            StyledRect {
                id: frame

                width: parent.width
                height: parent.height - inspector.height - Theme.spacingM
                radius: Theme.cornerRadius
                color: Theme.surface
                border.color: Theme.outline
                border.width: 1
                clip: true

                DFlickable {
                    id: galleryFlickable
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    contentHeight: gallery.height
                    clip: true

                    Column {
                        id: gallery

                        width: parent.width
                        spacing: Theme.spacingL

                        Section {
                            text: I18n.tr("Buttons")
                        }

                        Flow {
                            width: parent.width
                            spacing: Theme.spacingM

                            DButton {
                                property int clicks: 0

                                text: clicks > 0 ? `Clicked ${clicks}x` : "Filled"
                                iconName: "ads_click"
                                onClicked: clicks++
                            }

                            DButton {
                                text: "Tonal"
                                variant: "tonal"
                            }

                            DButton {
                                text: "Outlined"
                                variant: "outlined"
                            }

                            DButton {
                                text: "Text"
                                variant: "text"
                            }

                            DButton {
                                text: "Danger"
                                variant: "tonal"
                                danger: true
                            }

                            DButton {
                                text: "Large"
                                buttonHeight: 56
                                iconName: "schedule"
                                onClicked: timePicker.open()
                            }

                            DButton {
                                text: "Square button"
                                buttonHeight: 56
                                shape: "square"
                                iconName: "schedule"
                                onClicked: timePicker.open()
                            }

                            DActionButton {
                                iconName: "info"
                                buttonSize: Theme.iconButtonSize
                                tooltipText: I18n.tr("Icon button")
                            }

                            DRefreshButton {
                                property bool spin: false
                                busy: spin
                                onClicked: spin = !spin
                            }
                        }

                        DButtonGroup {
                            model: ["List", "Grid", "Tree"]
                            currentIndex: 0
                            onSelectionChanged: (index, selected) => {
                                if (selected)
                                    currentIndex = index;
                            }
                        }

                        Section {
                            text: "DSplitButton"
                        }

                        Column {
                            id: splitButtonExamples
                            width: parent.width
                            spacing: Theme.spacingM

                            DSplitButton {
                                id: splitSortButton
                                property bool descending: false
                                property string sortBy: I18n.tr("Name")
                                text: I18n.tr("Sort by") + ": " + sortBy
                                iconName: descending ? "arrow_downward" : "arrow_upward"
                                variant: "tonal"
                                maximumWidth: parent.width
                                expanded: splitSortMenu.menuVisible
                                tooltipText: descending ? I18n.tr("Ascending") : I18n.tr("Descending")
                                menuTooltipText: I18n.tr("Sort by")
                                onClicked: descending = !descending
                                onMenuClicked: {
                                    splitSortMenu.currentValue = sortBy;
                                    splitSortMenu.openDropdownMenu();
                                }

                                DDropdown {
                                    id: splitSortMenu
                                    showTrigger: false
                                    popupAnchorItem: splitSortButton.trailingButton
                                    focusReturnTarget: splitSortButton.trailingButton
                                    popupWidth: Math.min(splitButtonExamples.width, Theme.fieldDefaultWidth)
                                    options: [I18n.tr("Name"), I18n.tr("Author"), I18n.tr("Last modified")]
                                    onValueChanged: value => splitSortButton.sortBy = value
                                }
                            }

                            DSplitButton {
                                id: splitFilterButton
                                property string filter: I18n.tr("Enabled")
                                text: I18n.tr("Filter") + ": " + filter
                                iconName: "filter_list"
                                menuOnly: true
                                variant: "tonal"
                                maximumWidth: parent.width
                                expanded: splitFilterMenu.menuVisible
                                menuTooltipText: I18n.tr("Filter")
                                onMenuClicked: {
                                    splitFilterMenu.currentValue = filter;
                                    splitFilterMenu.openDropdownMenu();
                                }

                                DDropdown {
                                    id: splitFilterMenu
                                    showTrigger: false
                                    popupAnchorItem: splitFilterButton.trailingButton
                                    focusReturnTarget: splitFilterButton.trailingButton
                                    popupWidth: Math.min(splitButtonExamples.width, Theme.fieldDefaultWidth)
                                    options: [I18n.tr("All"), I18n.tr("Enabled"), I18n.tr("Disabled")]
                                    onValueChanged: value => splitFilterButton.filter = value
                                }
                            }

                            Flow {
                                width: parent.width
                                spacing: Theme.spacingM

                                Repeater {
                                    model: ["filled", "tonal", "outlined", "elevated"]

                                    DSplitButton {
                                        required property string modelData
                                        property int clicks: 0
                                        text: modelData + (clicks ? " · " + clicks : "")
                                        variant: modelData
                                        iconName: "add"
                                        maximumWidth: splitButtonExamples.width
                                        onClicked: clicks++
                                        onMenuClicked: expanded = !expanded
                                    }
                                }

                                DSplitButton {
                                    text: I18n.tr("Disabled")
                                    iconName: "add"
                                    enabled: false
                                    maximumWidth: splitButtonExamples.width
                                }
                            }

                            Repeater {
                                model: ["xs", "s", "m", "l", "xl"]

                                DSplitButton {
                                    required property string modelData
                                    property int clicks: 0
                                    text: modelData.toUpperCase() + (clicks ? " · " + clicks : "")
                                    size: modelData
                                    iconName: size === "l" || size === "xl" ? "" : "add"
                                    maximumWidth: splitButtonExamples.width
                                    onClicked: clicks++
                                    onMenuClicked: expanded = !expanded
                                }
                            }
                        }

                        DButtonGroup {
                            model: ["Mon", "Tue", "Wed", "Thu", "Fri"]
                            selectionMode: "multi"
                            initialSelection: ["Mon", "Fri"]
                        }

                        Section {
                            text: "DFab"
                        }

                        Flow {
                            width: parent.width
                            spacing: Theme.spacingM

                            Repeater {
                                model: ["primaryContainer", "secondaryContainer", "tertiaryContainer", "primary"]

                                DFab {
                                    required property string modelData
                                    text: modelData
                                    iconName: "edit"
                                    colorRole: modelData
                                }
                            }

                            DFab {
                                iconName: "add"
                                Accessible.name: I18n.tr("Add")
                            }

                            DFab {
                                property bool spin: false
                                text: I18n.tr("Sync")
                                iconName: "sync"
                                busy: spin
                                onClicked: spin = !spin
                            }
                        }

                        Section {
                            text: I18n.tr("Selection")
                        }

                        DToggle {
                            id: featureToggle

                            text: I18n.tr("Toggle")
                            description: "Spring thumb, M3 switch metrics"
                            checked: true
                            onToggled: checked => featureToggle.checked = checked
                        }

                        DToggle {
                            id: gatedToggle

                            text: "Gated toggle"
                            description: featureToggle.checked ? "Enabled by the one above" : "Disabled by the one above"
                            enabled: featureToggle.checked
                            onToggled: checked => gatedToggle.checked = checked
                        }

                        DFilterChips {
                            width: Math.min(340, gallery.width)
                            model: ["All", "Active", "Muted"]
                        }

                        DTabBar {
                            width: Math.min(340, gallery.width)
                            model: [
                                {
                                    "icon": "home",
                                    "text": "Home"
                                },
                                {
                                    "icon": "palette",
                                    "text": "Theme"
                                },
                                {
                                    "icon": "info",
                                    "text": "About"
                                }
                            ]
                            onTabClicked: index => currentIndex = index
                        }

                        Section {
                            text: I18n.tr("Sliders")
                        }

                        DSlider {
                            width: Math.min(340, gallery.width)
                            value: 50
                            step: 25
                            showStops: true
                            onSliderValueChanged: newValue => value = newValue
                        }

                        DSlider {
                            width: Math.min(340, gallery.width)
                            value: 30
                            enabled: false
                        }

                        DSlider {
                            width: Math.min(340, gallery.width)
                            value: 65
                            size: "m"
                            onSliderValueChanged: newValue => value = newValue
                        }

                        DSlider {
                            width: Math.min(340, gallery.width)
                            value: 65
                            size: "m"
                            onSliderValueChanged: newValue => value = newValue
                            insetIcon: "brightness_high"
                            insetIconPosition: "end"
                        }

                        DSlider {
                            width: Math.min(340, gallery.width)
                            value: 45
                            size: "xl"
                            startIcon: "brightness_low"
                            endIcon: "brightness_high"
                            iconsClickable: true
                            onSliderValueChanged: newValue => value = newValue
                        }

                        Section {
                            text: I18n.tr("Text fields")
                        }

                        Flow {
                            width: parent.width
                            spacing: Theme.spacingM

                            DSearchField {
                                width: Math.min(300, gallery.width)
                                placeholderText: "Search settings"
                            }

                            DTextField {
                                width: Math.min(300, gallery.width)
                                labelText: "Password"
                                outlined: true
                                leftIconName: "lock"
                                placeholderText: "Reveal with the eye"
                                echoMode: TextInput.Password
                                showPasswordToggle: true
                            }
                        }

                        WidgetGallery {
                            id: widgetExamples
                            width: parent.width
                            flickable: galleryFlickable
                        }

                        DTextEdit {
                            width: parent.width
                            leftIconName: "edit"
                            placeholderText: "Multi-line notes..."
                        }

                        DDropdown {
                            width: Math.min(320, gallery.width)
                            text: "Fruit"
                            description: "Fuzzy search enabled"
                            enableFuzzySearch: true
                            options: ["Apple", "Banana", "Cherry", "Dragonfruit", "Elderberry", "Fig", "Grape"]
                            currentValue: "Apple"
                            onValueChanged: value => currentValue = value
                        }

                        DCollapsibleSection {
                            width: Math.min(340, gallery.width)
                            title: "Details"
                            description: "Grouped header, expands below"
                            showBackground: true

                            StyledText {
                                text: "Collapsible content"
                            }
                        }

                        DNumberStepper {
                            property int count: 5

                            text: count
                            onIncrement: () => count++
                            onDecrement: () => count--
                        }

                        DTimePicker {
                            id: timePicker
                            parent: window.contentItem
                            hour: 7
                            minute: 0
                            onAccepted: (h, m) => root.log.info("time:", h, m)
                        }

                        Section {
                            text: I18n.tr("File browser")
                        }

                        Flow {
                            width: parent.width
                            spacing: Theme.spacingM

                            DButton {
                                text: I18n.tr("Pick a file")
                                iconName: "folder_open"
                                onClicked: fileBrowser.open()
                            }

                            DButton {
                                text: I18n.tr("Pick a folder")
                                iconName: "folder"
                                onClicked: folderBrowser.open()
                            }

                            DButton {
                                text: "Pick several files"
                                iconName: "library_add_check"
                                onClicked: multiBrowser.open()
                            }

                            DButton {
                                text: "Save a file"
                                iconName: "save"
                                onClicked: saveBrowser.open()
                            }
                        }

                        Section {
                            text: "Bottom sheet"
                        }

                        Flow {
                            width: parent.width
                            spacing: Theme.spacingM

                            DButton {
                                id: sheetOpener

                                text: I18n.tr("Open bottom sheet")
                                iconName: "expand_less"
                                onClicked: {
                                    bottomSheet.dismissible = true;
                                    bottomSheet.opened = true;
                                }
                            }

                            DButton {
                                text: I18n.tr("Open modal sheet")
                                iconName: "lock"
                                onClicked: {
                                    bottomSheet.dismissible = false;
                                    bottomSheet.opened = true;
                                }
                            }
                        }

                        DBottomSheet {
                            id: bottomSheet

                            parent: window.contentItem
                            title: I18n.tr("Outputs")
                            initialFocusItem: mirrorToggle
                            returnFocusItem: sheetOpener
                            onDismissRequested: opened = false

                            DToggle {
                                id: mirrorToggle

                                width: parent.width
                                text: "Mirror displays"
                                description: bottomSheet.dismissible ? "Swipe the handle or tap outside to close" : "Modal: use the button below"
                                checked: true
                                onToggled: value => mirrorToggle.checked = value
                            }

                            Repeater {
                                model: 8

                                DToggle {
                                    required property int index

                                    width: parent.width
                                    text: `Output ${index + 1}`
                                    description: index % 2 ? "1920x1080 · 60 Hz" : "2560x1440 · 144 Hz"
                                    onToggled: value => checked = value
                                }
                            }

                            DButton {
                                width: parent.width
                                text: I18n.tr("Close")
                                onClicked: bottomSheet.opened = false
                            }
                        }

                        Section {
                            text: "Icons"
                        }

                        Flow {
                            width: parent.width
                            spacing: Theme.spacingM

                            DIcon {
                                name: "palette"
                                color: Theme.primary
                            }

                            DIcon {
                                name: "favorite"
                                filled: true
                                color: Theme.error
                            }

                            DNFIcon {
                                name: "arch"
                                size: Theme.iconSizeLarge
                            }

                            DNFIcon {
                                name: "file"
                                size: Theme.iconSizeLarge
                            }

                            DColorSwatch {
                                swatchColor: Theme.primary
                            }

                            DColorSwatch {
                                swatchColor: Theme.withAlpha(Theme.secondary, 0.5)
                            }

                            DSpinner {
                                size: Theme.iconSizeLarge
                            }

                            DLoadingIndicator {}

                            DLoadingIndicator {
                                contained: true
                            }
                        }

                        Section {
                            text: "List view"
                        }

                        StyledRect {
                            width: Math.min(340, gallery.width)
                            height: 180
                            color: Theme.surfaceContainer
                            radius: Theme.cornerRadius

                            DListView {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingS
                                clip: true
                                model: 20
                                spacing: Theme.spacingXXS

                                delegate: StyledRect {
                                    id: listRow

                                    required property int index

                                    width: parent ? parent.width : 0
                                    height: 36
                                    radius: Theme.cornerRadius
                                    color: rowLayer.containsMouse ? Theme.surfacePressed : "transparent"

                                    StyledText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: Theme.spacingM
                                        text: `Row ${listRow.index + 1}`
                                    }

                                    StateLayer {
                                        id: rowLayer

                                        cornerRadius: Theme.cornerRadius
                                        onClicked: root.log.info("row clicked:", listRow.index + 1)
                                    }
                                }
                            }
                        }

                        Section {
                            text: "Grid view"
                        }

                        StyledRect {
                            width: Math.min(340, gallery.width)
                            height: 180
                            color: Theme.surfaceContainer
                            radius: Theme.cornerRadius

                            DGridView {
                                anchors.fill: parent
                                anchors.margins: Theme.spacingS
                                clip: true
                                model: 40
                                cellWidth: 64
                                cellHeight: 64

                                delegate: Item {
                                    id: gridCell

                                    required property int index

                                    width: 64
                                    height: 64

                                    StyledRect {
                                        anchors.fill: parent
                                        anchors.margins: Theme.spacingXS
                                        radius: Theme.cornerRadius
                                        color: Theme.withAlpha(Theme.primary, 0.1 + (gridCell.index % 8) * 0.1)

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: gridCell.index + 1
                                            font.pixelSize: Theme.fontSizeSmall
                                        }
                                    }
                                }
                            }
                        }

                        Section {
                            text: "Surfaces and elevation"
                        }

                        StyledRect {
                            id: card

                            width: Math.min(340, gallery.width)
                            height: 100
                            color: Theme.surfaceContainerHigh
                            radius: Theme.cornerRadius

                            DC.ElevationShadow {
                                anchors.fill: parent
                                z: -1
                                targetRadius: card.radius
                                targetColor: card.color
                            }

                            StyledText {
                                anchors.centerIn: parent
                                text: "StyledRect + ElevationShadow + StateLayer"
                                width: parent.width - Theme.spacingL * 2
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }

                            StateLayer {
                                cornerRadius: card.radius
                                onClicked: root.log.info("card clicked")
                            }
                        }

                        Section {
                            text: I18n.tr("Progress")
                        }

                        DSlider {
                            width: Math.min(340, gallery.width)
                            value: 40
                            startIcon: "volume_down"
                            endIcon: "volume_up"
                            iconsClickable: true
                            onSliderValueChanged: newValue => root.log.info("slider:", newValue)
                        }

                        M3WaveProgress {
                            width: Math.min(340, gallery.width)
                            height: 24
                            value: 0.6
                            isPlaying: true
                        }

                        Section {
                            text: "Avatars and logos"
                        }

                        Flow {
                            width: parent.width
                            spacing: Theme.spacingL

                            DCircularImage {
                                width: 48
                                height: 48
                                fallbackIcon: "person"
                                fallbackText: "DK"
                            }

                            SystemLogo {
                                width: 48
                                height: 48
                            }
                        }

                        Section {
                            text: "Numeric text"
                        }

                        NumericText {
                            text: "1234.56"
                            reserveText: "8888.88"
                            font.pixelSize: Theme.fontSizeXLarge
                        }

                        Section {
                            text: "Icon picker"
                        }

                        DIconPicker {
                            onIconSelected: (iconName, iconType) => root.log.info("icon:", iconName, iconType)
                        }

                        Section {
                            text: "Location search"
                        }

                        DLocationSearch {
                            width: Math.min(340, gallery.width)
                            onLocationSelected: (displayName, coordinates) => root.log.info("location:", displayName, coordinates)
                        }

                        Section {
                            text: "Cursor and blink"
                        }

                        Flow {
                            width: parent.width
                            spacing: Theme.spacingL

                            StyledText {
                                id: blinkTarget

                                text: "DBlink target"
                            }

                            DBlink {
                                target: blinkTarget
                            }

                            DTextCursor {
                                height: 20
                            }
                        }

                        Item {
                            width: 1
                            height: Theme.spacingL
                        }
                    }
                }
            }
        }
    }

    component Section: StyledText {
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Style.fontWeightMedium
        color: Theme.primary
    }

    FileBrowserModal {
        id: fileBrowser

        browserTitle: "Pick a file"
        bucket: "gallery"
        filters: ["*.png", "*.jpg", "*.svg", "*.webp"]
        startPath: "/home/alice/Pictures/city.jpg"
        onAccepted: paths => root.log.info("file selected:", paths)
    }

    FileBrowserModal {
        id: folderBrowser

        browserTitle: "Pick a folder"
        mode: "openFolder"
        bucket: "gallery-folder"
        onAccepted: paths => root.log.info("folder selected:", paths)
    }

    FileBrowserModal {
        id: multiBrowser

        browserTitle: "Pick several files"
        bucket: "gallery"
        multiple: true
        onAccepted: paths => root.log.info("files selected:", paths)
    }

    FileBrowserModal {
        id: saveBrowser

        browserTitle: "Save a file"
        mode: "save"
        bucket: "gallery-save"
        defaultName: "theme.json"
        filters: ["*.json"]
        onAccepted: paths => root.log.info("save to:", paths)
    }
}
