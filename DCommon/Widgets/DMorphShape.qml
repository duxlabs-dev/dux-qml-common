import "MaterialShapes.js" as Shapes
import QtQuick
import qs.DCommon.Common

Item {
    id: root

    // Catalog names the shape can morph between; from and to pick two of them
    property var shapes: ["cookie4"]
    property string from: shapes[0]
    property string to: from
    property real progress: 1
    property color color: Style.primary
    // Share of the item's box the shapes fill
    property real fill: 1

    readonly property int samples: 256
    readonly property var profiles: shapes.map(kind => Shapes.polarProfile(kind, samples))
    readonly property var centers: profiles.map(radii => {
        const bounds = Shapes.polarBounds(radii);
        return Qt.point(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2);
    })
    readonly property real shapeScale: Shapes.morphScale(profiles) * fill

    implicitWidth: Style.iconButtonSize
    implicitHeight: Style.iconButtonSize

    Canvas {
        id: profileTexture

        width: root.samples
        height: root.shapes.length
        visible: false
        onPaint: {
            const context = getContext("2d");
            root.profiles.forEach((radii, row) => radii.forEach((radius, column) => {
                    const value = Math.round(Math.max(0, Math.min(1, radius)) * 65535);
                    context.fillStyle = Qt.rgba((value >> 8) / 255, (value & 255) / 255, 0, 1);
                    context.fillRect(column, row, 1, 1);
                }));
        }
    }

    ShaderEffect {
        readonly property int fromShape: Math.max(0, root.shapes.indexOf(root.from))
        readonly property int toShape: Math.max(0, root.shapes.indexOf(root.to))
        readonly property point fromCenter: root.centers[fromShape] ?? Qt.point(0, 0)
        readonly property point toCenter: root.centers[toShape] ?? Qt.point(0, 0)

        property var profiles: profileTexture
        property color color: root.color
        property point offset: Qt.point((fromCenter.x + (toCenter.x - fromCenter.x) * progress) * unitPx, (fromCenter.y + (toCenter.y - fromCenter.y) * progress) * unitPx)
        property real sizePx: width
        property real unitPx: width * root.shapeScale
        property real fromRow: fromShape
        property real toRow: toShape
        property real progress: Math.max(0, Math.min(1, root.progress))
        property real angle: 0
        property real rows: root.shapes.length
        property real samples: root.samples

        anchors.centerIn: parent
        width: Math.min(root.width, root.height)
        height: width
        fragmentShader: Qt.resolvedUrl("../Shaders/qsb/loading_indicator.frag.qsb")
    }
}
