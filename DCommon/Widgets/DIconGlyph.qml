import QtQuick
import qs.DCommon.Common

Text {
    font.family: Fonts.icons
    font.hintingPreference: Font.PreferNoHinting
    textFormat: Text.PlainText
    wrapMode: Text.WordWrap
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    renderTypeQuality: {
        switch (Style.textRenderQuality) {
        case Style.TextRenderQuality.Low:
            return Text.LowRenderTypeQuality;
        case Style.TextRenderQuality.Normal:
            return Text.NormalRenderTypeQuality;
        case Style.TextRenderQuality.High:
            return Text.HighRenderTypeQuality;
        case Style.TextRenderQuality.VeryHigh:
            return Text.VeryHighRenderTypeQuality;
        default:
            return Text.DefaultRenderTypeQuality;
        }
    }
}
