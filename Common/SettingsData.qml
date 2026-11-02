pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    enum AnimationSpeed {
        None,
        Short,
        Medium,
        Long,
        Custom
    }

    enum TextRenderType {
        Qt,
        Native,
        Curve
    }

    enum TextRenderQuality {
        Default,
        Low,
        Normal,
        High,
        VeryHigh
    }

    property int animationSpeed: SettingsData.AnimationSpeed.Short
    property bool reduceMotion: false
    property bool blurBorderEnabled: false
    property real blurLayerOutlineOpacity: 0
    property real blurBorderOpacity: 0.35
    property string blurBorderColor: "outline"
    property string blurBorderCustomColor: "#ffffff"
    property int springBounce: 1
    property bool enableRippleEffects: true
    property bool powerActionConfirm: true
    property real powerActionHoldDuration: 0.5
    property var powerMenuActions: ["reboot", "logout", "poweroff", "lock", "suspend", "restart"]
    property string powerMenuDefaultAction: "logout"
    property bool powerMenuGridLayout: false
    property bool popoutElevationEnabled: true
    property bool scrollbarsEnabled: true
    property bool showExtensions: true
    property string dateFormat: "locale"
    property int textRenderType: SettingsData.TextRenderType.Qt
    property int textRenderQuality: SettingsData.TextRenderQuality.Default
}
