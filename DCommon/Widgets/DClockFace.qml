import QtQuick
import qs.DCommon.Common

Item {
    id: root

    property string hours: "00"
    property string minutes: "00"
    property string seconds: ""
    property string dateText: ""
    property bool stacked: false
    property color color: Style.primary
    property color minutesColor: color
    property color secondsColor: minutesColor
    property color supportingColor: Style.onSurfaceVariant
    property string fontFamily: ""
    property int weight: 0
    property bool rounded: true

    readonly property bool variableFont: fontFamily === "" || fontFamily === Style.defaultFontFamily
    readonly property int digitWeight: weight > 0 ? weight : 750
    readonly property real referenceSize: 100
    readonly property string digitFamily: fontFamily || Style.fontFor("ui")
    readonly property int staticWeight: Math.min(Font.Black, digitWeight)

    readonly property bool tall: height > Style.buttonHeightM * 2
    readonly property bool vertical: tall && (stacked || height > width * 0.6)
    readonly property bool inlineSeconds: seconds !== "" && !vertical && width / fullAdvance >= Style.fontSizeDisplay
    readonly property string timeText: hours + ":" + minutes + (inlineSeconds ? ":" + seconds : "")
    readonly property string supportText: [dateText, inlineSeconds ? "" : seconds].filter(s => s !== "").join(" · ")
    readonly property bool hasSupport: supportText !== "" && height - support.height - supportGap >= Style.fontSizeLarge

    readonly property real opticalSize: vertical ? height / 2 : height
    readonly property var digitAxes: variableFont ? {
        "ROND": rounded ? 100 : 20,
        "wght": digitWeight,
        "opsz": opticalSize
    } : {}
    readonly property font metricsFont: Qt.font({
        "family": digitFamily,
        "pixelSize": referenceSize,
        "weight": variableFont ? Font.Normal : staticWeight,
        "variableAxes": digitAxes
    })
    readonly property string widestDigit: Fonts.widestDigit(metricsFont)
    readonly property rect digitInk: digitMetrics.tightBoundingRect
    readonly property real inkRatio: Math.max(0.01, digitInk.height / referenceSize)
    readonly property real rowAdvance: Math.max(0.01, rowMetrics.advanceWidth / referenceSize)
    readonly property real fullAdvance: Math.max(0.01, fullMetrics.advanceWidth / referenceSize)
    readonly property real widthSize: width / rowAdvance
    readonly property real estimateSize: Math.min(widthSize, (vertical ? height / 2 : height) / inkRatio)
    readonly property real supportSize: Math.max(Style.fontSizeMedium, estimateSize * inkRatio * 0.25)
    readonly property real supportGap: supportSize * 0.3
    readonly property real supportHeight: hasSupport ? support.height + supportGap : 0
    readonly property real digitsHeight: height - supportHeight
    readonly property real rowGap: vertical ? digitsHeight * 0.06 : 0
    readonly property real rowHeight: vertical ? (digitsHeight - rowGap) / 2 : digitsHeight
    readonly property real digitSize: Math.max(1, Math.min(widthSize, rowHeight / inkRatio))
    readonly property real inkHeight: digitSize * inkRatio
    readonly property real blockHeight: inkHeight * (vertical ? 2 : 1) + rowGap + supportHeight
    readonly property real blockTop: (height - blockHeight) / 2

    implicitWidth: Style.fontSizeDisplay * 6
    implicitHeight: Style.fontSizeDisplay * 4

    function escapedDigits(text) {
        return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    function span(text, spanColor) {
        return spanColor === root.color ? escapedDigits(text) : `<font color="${spanColor}">${escapedDigits(text)}</font>`;
    }

    function inkTop(label) {
        return label.baselineOffset + digitInk.y * digitSize / referenceSize;
    }

    TextMetrics {
        id: digitMetrics
        font: root.metricsFont
        text: "0123456789"
    }

    TextMetrics {
        id: fullMetrics
        font: root.metricsFont
        text: (root.hours + ":" + root.minutes + ":" + root.seconds).replace(/\d/g, root.widestDigit)
    }

    TextMetrics {
        id: rowMetrics
        font: root.metricsFont
        text: (root.vertical ? (root.hours.length > root.minutes.length ? root.hours : root.minutes) : root.timeText).replace(/\d/g, root.widestDigit)
    }

    Digits {
        id: digitsRow
        readonly property bool accented: !root.vertical && (root.minutesColor !== root.color || (root.inlineSeconds && root.secondsColor !== root.color))
        y: root.blockTop - root.inkTop(digitsRow)
        textFormat: accented ? Text.StyledText : Text.PlainText
        text: {
            if (root.vertical)
                return root.hours;
            if (!accented)
                return root.timeText;
            return root.escapedDigits(root.hours + ":") + root.span(root.minutes, root.minutesColor) + (root.inlineSeconds ? root.span(":" + root.seconds, root.secondsColor) : "");
        }
    }

    Digits {
        id: minutesRow
        visible: root.vertical
        y: root.blockTop + root.inkHeight + root.rowGap - root.inkTop(minutesRow)
        text: root.minutes
        color: root.minutesColor
    }

    StyledText {
        id: support
        visible: root.hasSupport
        y: root.blockTop + root.blockHeight - height
        width: root.width
        text: root.supportText
        color: root.supportingColor
        font.pixelSize: root.supportSize
        font.weight: Style.fontWeightMedium
        minimumPixelSize: Style.fontSizeSmall
        fontSizeMode: Text.HorizontalFit
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignTop
        wrapMode: Text.NoWrap
        elide: Text.ElideRight
    }

    component Digits: StyledText {
        width: root.width
        color: root.color
        font.pixelSize: root.digitSize
        font.family: root.digitFamily
        // only Normal resolves to the variable face, other weights pick axis-less static instances
        font.weight: root.variableFont ? Font.Normal : root.staticWeight
        font.variableAxes: root.digitAxes
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignTop
        wrapMode: Text.NoWrap
        elide: Text.ElideNone
        LayoutMirroring.enabled: false
    }
}
