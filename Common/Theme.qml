pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import "../DCommon/Common/Shape.js" as Shape
import "../DCommon/Common/Surface.js" as Surface
import "../DCommon/Common/Accents.js" as Accents
import Quickshell
import qs.DCommon.Common

Singleton {
    id: root

    readonly property bool isLightMode: false

    property color primary: "#D0BCFF"
    readonly property color contrastDark: "#000000"
    readonly property color contrastLight: "#ffffff"
    property color primaryText: "#381E72"
    property color primaryContainer: "#4F378B"
    readonly property real selectedContainerTint: 0.2
    property bool themedSelectedContainer: true
    property color selectedContainer: secondaryContainer
    property color accentOnSelectedContainer: primary
    property color accentOnPrimaryContainer: primary
    readonly property var accents: Accents.derive(primary, isLightMode, null)
    property color secondary: "#CCC2DC"
    property color surface: "#141218"
    property color surfaceText: "#E6E0E9"
    property color surfaceVariant: "#49454F"
    property color surfaceVariantText: "#CAC4D0"
    property color background: "#141218"
    property color outline: "#938F99"
    property color surfaceContainer: "#211F26"
    property color surfaceContainerHigh: "#2B2930"
    property color error: "#F2B8B5"
    property color errorContainer: "#8C1D18"
    property color tertiary: "#EFB8C8"
    property color surfaceContainerLowest: "#0F0D13"
    property color surfaceContainerLow: "#1D1B20"
    property color surfaceContainerHighest: "#36343B"
    property color surfaceBright: "#3B383E"
    property color surfaceDim: "#141218"
    property color hostSurface: "#141218"
    property color cardSurface: "#211F26"
    property color chipSurface: "#2B2930"
    property color chipSurfaceNested: "#36343B"
    property color tooltipSurface: "#E6E0E9"
    property color tooltipText: "#322F35"
    property color outlineVariant: "#49454F"
    property color secondaryContainer: "#4A4458"
    property color tertiaryContainer: "#633B48"
    property color inverseSurface: "#E6E0E9"
    property color inverseOnSurface: "#322F35"
    property color onSurface
    property color onPrimary
    property color onSurfaceVariant
    property color onPrimaryContainer
    property color onSecondaryContainer
    property color onErrorContainer
    property color onTertiaryContainer
    property color onSelectedContainer
    property color onSurfaceVariant_30: withAlpha(onSurfaceVariant, 0.3)
    property color onSurfaceVariant_40
    readonly property list<QtObject> roleBindings: [
        Binding {
            target: root
            property: "onSurfaceVariant_40"
            value: root.withAlpha(root.onSurfaceVariant, 0.4)
        },
        Binding {
            target: root
            property: "onErrorContainer"
            value: "#F9DEDC"
        },
        Binding {
            target: root
            property: "onSurface"
            value: root.surfaceText
        },
        Binding {
            target: root
            property: "onPrimary"
            value: root.primaryText
        },
        Binding {
            target: root
            property: "onSurfaceVariant"
            value: root.surfaceVariantText
        },
        Binding {
            target: root
            property: "onPrimaryContainer"
            value: "#EADDFF"
        },
        Binding {
            target: root
            property: "onSecondaryContainer"
            value: "#E8DEF8"
        },
        Binding {
            target: root
            property: "onTertiaryContainer"
            value: "#FFD8E4"
        },
        Binding {
            target: root
            property: "onSelectedContainer"
            value: "#EADDFF"
        }
    ]
    readonly property real tonalTintAlpha: 0.16

    property color warning: "#FF9800"

    property color onSurface_10: withAlpha(onSurface, 0.1)
    property color onSurface_12: withAlpha(onSurface, 0.12)
    property color onSurface_38: withAlpha(onSurface, 0.38)
    property color surfaceTint: primary
    property color surfaceLight: withAlpha(surfaceVariant, 0.1)

    property color primaryHover: withAlpha(primary, 0.12)
    property color primaryHoverLight: withAlpha(primary, 0.08)
    property color primaryPressed: withAlpha(primary, 0.16)
    property color primarySelected: withAlpha(primary, 0.3)
    property color errorHover: withAlpha(error, 0.12)
    property color errorSelected: withAlpha(error, 0.3)
    property color surfaceHover: withAlpha(surfaceVariant, 0.08)
    property color surfacePressed: withAlpha(surfaceVariant, 0.12)
    property color surfaceVariantAlpha: withAlpha(surfaceVariant, 0.2)
    property color surfaceTextHover: withAlpha(surfaceText, 0.08)
    property color surfaceTextMedium: withAlpha(surfaceText, 0.7)
    property color surfaceTextSecondary: withAlpha(surfaceText, 0.6)
    property color outlineButton: withAlpha(outline, 0.5)
    property color outlineMedium: withAlpha(outline, layerOutlineOpacity)
    property color outlineStrong: withAlpha(outline, Math.min(1, layerOutlineOpacity * 1.5))
    property color outlineHeavy: withAlpha(outline, 0.2)
    property color shadowStrong: Qt.rgba(0, 0, 0, 0.3)

    property color buttonBg: primary
    property color buttonText: primaryText
    property color buttonHover: primaryHover
    property color buttonPressed: withAlpha(primary, 0.16)

    property real popupTransparency: 1.0
    property bool foregroundLayers: true
    property real foregroundLayerTransparency: 1.0
    readonly property real foregroundAlpha: Surface.foregroundAlpha(foregroundLayers, foregroundLayerTransparency)
    readonly property color floatingSurface: withAlpha(hostSurface, popupTransparency)
    readonly property color nestedSurface: withAlpha(cardSurface, foregroundAlpha)

    property real floatingWindowTransparency: popupTransparency
    property bool floatingWindowForegroundLayers: foregroundLayers
    property real floatingWindowForegroundTransparency: foregroundLayerTransparency
    readonly property real floatingWindowForegroundAlpha: Surface.foregroundAlpha(floatingWindowForegroundLayers, floatingWindowForegroundTransparency)
    property color floatingWindowSurface: withAlpha(hostSurface, floatingWindowTransparency)
    property color floatingWindowNestedSurface: withAlpha(cardSurface, floatingWindowForegroundAlpha)
    property color floatingWindowFieldColor: withAlpha(chipSurface, floatingWindowForegroundAlpha)
    property color floatingWindowFieldBorderColor: withAlpha(outline, 0.16)
    property color floatingWindowFieldFocusedBorderColor: primary
    property color popupFieldColor: withAlpha(chipSurface, foregroundAlpha)
    property color popupFieldBorderColor: withAlpha(outline, 0.16)
    property color popupFieldFocusedBorderColor: primary
    property bool blurLayersActive: true

    property color widgetBaseHoverColor: {
        const blended = blend(surfaceContainerHigh, primary, 0.1);
        return withAlpha(blended, Math.max(0.3, blended.a));
    }

    property real spacingXXS: 2
    property real spacingXS: 4
    property real spacingS: 8
    property real spacingM: 12
    readonly property real windowInset: spacingM
    property real spacingL: 16
    property real spacingXL: 24

    property real fontSizeSmall: 12
    property real fontSizeMedium: 14
    property real fontSizeLarge: 16
    property real fontSizeXLarge: 20
    property real fontSizeXXLarge: 28
    property real fontSizeDisplay: 36
    property real fontSizeDisplayLarge: 57

    property real iconSizeSmall: 16
    property real iconSize: 24
    property real iconSizeLarge: 32

    property real radiusStrength: 50
    property real fixedRadius: -1
    readonly property real shapeScale: fixedRadius >= 0 ? fixedRadius / Shape.corners.m : Shape.scaleForStrength(radiusStrength)
    readonly property real cornerRadius: cornerRadiusM
    readonly property real cornerRadiusXXS: Shape.radius("xxs", shapeScale, fixedRadius)
    readonly property real cornerRadiusXS: Shape.radius("xs", shapeScale, fixedRadius)
    readonly property real cornerRadiusS: Shape.radius("s", shapeScale, fixedRadius)
    readonly property real cornerRadiusM: Shape.radius("m", shapeScale, fixedRadius)
    readonly property real cornerRadiusL: Shape.radius("l", shapeScale, fixedRadius)
    readonly property real cornerRadiusLIncreased: Shape.radius("lIncreased", shapeScale, fixedRadius)
    readonly property real cornerRadiusXL: Shape.radius("xl", shapeScale, fixedRadius)
    readonly property real cornerRadiusXLIncreased: Shape.radius("xlIncreased", shapeScale, fixedRadius)
    readonly property real cornerRadiusXXL: Shape.radius("xxl", shapeScale, fixedRadius)
    readonly property real cornerRadiusFull: fixedRadius >= 0 ? fixedRadius : (shapeScale > 0 ? 9999 : 0)
    readonly property real cornerRadiusSmall: cornerRadiusS
    readonly property real cornerRadiusLarge: cornerRadiusL
    readonly property real windowRadius: cornerRadiusL

    function scaledRadius(radius, limit) {
        return Shape.scaledRadius(radius, limit, shapeScale, fixedRadius);
    }

    function innerRadius(token) {
        return Shape.innerRadius(token, shapeScale, fixedRadius);
    }

    function fullRadius(width, height) {
        return Shape.fullRadius(width, height, shapeScale, fixedRadius);
    }

    property bool shapeMorph: true
    property bool pillControls: true

    function buttonRadius(width, height, sizeHeight, pressed, round) {
        return Shape.buttonRadius(width, height, sizeHeight, pressed, round, shapeScale, fixedRadius, shapeMorph, pillControls);
    }

    readonly property int densityLevel: 0
    readonly property real groupedListGap: spacingXXS
    readonly property real groupedListInnerRadius: innerRadius("xs")
    readonly property real groupedListOuterRadius: cornerRadiusL
    readonly property real iconButtonSize: 40
    readonly property real minimumTouchTargetSize: 48
    readonly property real listItemHeight: 56
    readonly property real listItemTwoLineHeight: 72
    readonly property real avatarSize: 36
    readonly property real sliderTrackHeight: 16
    readonly property real sliderHandleWidth: 4
    readonly property real sliderHandleWidthPressed: 2
    readonly property real sliderHandleHeight: 44
    readonly property real sliderHandleGap: 6
    readonly property real sliderTrackHeightS: 24
    readonly property real sliderHandleHeightS: 36
    readonly property real sliderTrackHeightM: 40
    readonly property real sliderHandleHeightM: 52
    readonly property real sliderTrackHeightL: 56
    readonly property real sliderHandleHeightL: 68
    readonly property real sliderTrackHeightXL: 96
    readonly property real sliderHandleHeightXL: 108
    readonly property real switchTrackWidth: 52
    readonly property real switchTrackHeight: 32
    readonly property real switchOutlineWidth: 2
    readonly property real switchThumbUnselected: 16
    readonly property real switchThumbSelected: 24
    readonly property real switchThumbPressed: 28
    readonly property real sliderStopSize: 4
    readonly property real sliderTickSize: 3
    readonly property real sliderTrackMinAlpha: 0.4
    readonly property real menuItemHeight: 40
    readonly property real outlineWidth: 1
    readonly property real outlineWidthFocused: 2
    readonly property real layerOutlineOpacity: Math.max(0, Math.min(1, SettingsData.blurLayerOutlineOpacity))
    readonly property int layerOutlineWidth: layerOutlineOpacity > 0 ? 1 : 0
    readonly property real dividerWidth: 1
    readonly property real focusRingWidth: 1.5
    readonly property real focusRingOffset: 3
    readonly property color focusRingColor: primary
    readonly property color lockScreenContentColor: "#ffffff"
    readonly property real lockScreenScrimAlpha: 0.4
    readonly property real lockScreenBlur: 0.8
    readonly property int lockScreenBlurMax: 32
    readonly property color screenOffColor: "#000000"
    readonly property real scrimAlpha: 0.55
    readonly property color scrimColor: "#000000"
    readonly property real buttonHeightXXS: 28
    readonly property real buttonHeightXS: 32
    readonly property real buttonHeightS: 40
    readonly property real buttonHeightM: 56
    readonly property real buttonMinWidth: 58
    readonly property real pressScale: 0.98
    readonly property real iconEnterScale: 0.6
    readonly property real osdHeight: 60
    readonly property real dialogMaxWidth: 560
    readonly property real sidebarWidth: 240
    readonly property real bottomSheetHandleWidth: 36
    readonly property real bottomSheetHandleHeight: 4
    readonly property real popupEnterScale: 0.92
    readonly property real pendingOpacity: 0.6
    readonly property real spinnerStrokeWidth: 2
    readonly property real tabMinWidth: 64
    readonly property real tabIndicatorHeight: 3
    readonly property real navigationHeight: 64
    readonly property real navigationRailWidth: 96
    readonly property real navigationItemMinWidth: 80
    readonly property real navigationIndicatorWidth: 56
    readonly property real navigationIndicatorHeight: 32
    readonly property real navigationVerticalPadding: 6
    readonly property real tabIndicatorMinWidth: 24
    readonly property real tabIndicatorInset: 2
    readonly property real launcherTileSize: 120
    readonly property real launcherImageRatio: 0.75
    readonly property int launcherMaxVisibleRows: 8
    readonly property real launcherWidthMicro: 500
    readonly property real launcherWidthDefault: 620
    readonly property real launcherWidthWide: 720
    readonly property real launcherWidthLarge: 860
    readonly property real launcherHeightDefault: 600
    readonly property real launcherScreenMargin: 100

    readonly property real fieldDefaultWidth: 200
    readonly property real fieldHeight: Math.round(fontSizeMedium * 3)
    readonly property real fieldHeightLarge: 48
    readonly property real outlinedFieldLabelLineHeight: 16
    readonly property real textEditHeight: Math.round(fontSizeMedium * 8)
    readonly property real tooltipMaxWidth: 300
    readonly property int tooltipDelay: 400
    readonly property real tooltipEnterScale: 0.8
    readonly property real scrollbarThickness: 6
    readonly property real scrollbarGap: spacingXS
    readonly property int scrollbarHideDelay: 1200
    readonly property real menuMaxHeight: 400
    readonly property real clockFaceSize: 256
    readonly property real clockOuterRingRatio: 101 / clockFaceSize
    readonly property real clockInnerRingRatio: 69 / clockFaceSize
    readonly property real clockHandWidth: 2
    readonly property real clockHandleSize: 48
    readonly property real clockCenterSize: 8
    readonly property int clockSwitchDelay: 100
    readonly property real chipIconSize: 18
    readonly property real buttonGroupExpandRatio: 0.15
    readonly property real iconSizeMedium: 20
    readonly property int smallBreakpoint: 480
    readonly property int mediumBreakpoint: 768
    readonly property bool connectedSurfaceBlurEnabled: true
    readonly property string elevationLightDirection: "top"

    readonly property string defaultFontFamily: Fonts.sans
    readonly property string defaultMonoFontFamily: Fonts.mono
    readonly property string defaultDisplayFontFamily: Fonts.display
    property string fontFamily: defaultFontFamily
    property string monoFontFamily: defaultMonoFontFamily
    property string displayFontFamily: defaultDisplayFontFamily
    property int fontWeight: Font.Normal

    property int shorterDuration: 100
    property int shortDuration: 200
    property int mediumDuration: 350
    property int standardEasing: Easing.OutCubic
    property int emphasizedEasing: Easing.OutQuart

    readonly property int currentAnimationSpeed: SettingsData.animationSpeed
    readonly property int currentAnimationBaseDuration: 500
    readonly property bool elevationEnabled: true

    readonly property real stateLayerHover: 0.08
    readonly property real stateLayerFocus: 0.1
    readonly property real stateLayerPressed: 0.1
    readonly property real stateLayerDrag: 0.16

    readonly property var springSpecs: ({
            "expressive": [560, 37],
            "fast": [220, 23],
            "default": [300, 24],
            "fastSpatial": [800, 33.9],
            "defaultSpatial": [380, 31.2],
            "slowSpatial": [200, 22.6],
            "fastEffects": [3800, 123.3],
            "defaultEffects": [1600, 80],
            "slowEffects": [800, 56.6]
        })
    readonly property var springDampingScales: [1.22, 1.0, 0.82]
    readonly property bool springMotionDisabled: currentAnimationBaseDuration <= 0

    function springPreset(name, baseDuration) {
        const spec = springSpecs[name] ?? springSpecs["default"];
        const f = Math.max(0.05, baseDuration / 500);
        const bounce = springDampingScales[Math.round(SettingsData.springBounce)] ?? 1;
        return {
            "stiffness": spec[0] / (f * f),
            "damping": spec[1] / f * bounce,
            "mass": 1
        };
    }

    readonly property var elevationLevel1: ({
            blurPx: 4,
            offsetX: 0,
            offsetY: 1,
            spreadPx: 0,
            alpha: 0.2
        })
    readonly property var elevationLevel3: ({
            blurPx: 12,
            offsetX: 0,
            offsetY: 6,
            spreadPx: 0,
            alpha: 0.3
        })

    readonly property var elevationLevel2: ({
            blurPx: 8,
            offsetX: 4,
            offsetY: 4,
            spreadPx: 0,
            alpha: 0.25
        })

    readonly property var expressiveCurves: ({
            "emphasized": [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1],
            "emphasizedAccel": [0.3, 0, 0.8, 0.15, 1, 1],
            "emphasizedDecel": [0.05, 0.7, 0.1, 1, 1, 1],
            "standard": [0.2, 0, 0, 1, 1, 1],
            "standardAccel": [0.3, 0, 1, 1, 1, 1],
            "standardDecel": [0, 0, 0, 1, 1, 1],
            "expressiveFastSpatial": [0.42, 1.67, 0.21, 0.9, 1, 1],
            "expressiveDefaultSpatial": [0.38, 1.21, 0.22, 1, 1, 1],
            "expressiveSlowSpatial": [0.39, 1.29, 0.35, 0.98, 1, 1],
            "expressiveFastEffects": [0.31, 0.94, 0.34, 1, 1, 1],
            "expressiveEffects": [0.34, 0.8, 0.34, 1, 1, 1],
            "expressiveSlowEffects": [0.34, 0.88, 0.34, 1, 1, 1]
        })

    readonly property var expressiveDurations: ({
            "fast": 200,
            "normal": 400,
            "large": 600,
            "extraLarge": 1000,
            "expressiveFastSpatial": 350,
            "expressiveDefaultSpatial": 500,
            "expressiveSlowSpatial": 650,
            "expressiveFastEffects": 150,
            "expressiveEffects": 200,
            "expressiveSlowEffects": 300
        })

    function withAlpha(c, a) {
        return Style.withAlpha(c, a);
    }

    function blendAlpha(c, a) {
        return Style.blendAlpha(c, a);
    }

    function blend(c1, c2, r) {
        return Qt.rgba(c1.r * (1 - r) + c2.r * r, c1.g * (1 - r) + c2.g * r, c1.b * (1 - r) + c2.b * r, c1.a * (1 - r) + c2.a * r);
    }
}
