import QtQuick
import qs.DCommon.Common
import "PressBounce.js" as Bounce

// M3 Expressive button group press: the pressed item widens, its direct neighbors narrow.
QtObject {
    id: root

    // Rest geometry, one {x, y, w, h} or null per item.
    property var slots: []
    property real ratio: Style.buttonGroupExpandRatio
    // Caps growth at ratio of this width, so wide items move no more than narrow ones.
    property real unit: Infinity
    // Optional (index) => width an item never narrows below.
    property var minimumWidth: null
    property var spring: Style.springPreset("fastSpatial")
    property bool enabled: Style.shapeMorph
    property bool animated: true
    property int index: -1
    // At rest nothing reads the slots, so layout changes cost nothing.
    readonly property bool active: index >= 0 && (motion.value !== 0 || motion.target !== 0)
    readonly property var shifts: active ? Bounce.shifts(slots, index, ratio, unit, minimumWidth) : []

    function press(item: int, pressed: bool) {
        if (pressed && enabled) {
            if (index !== item)
                motion.snapTo(0);
            index = item;
            motion.retarget(1);
            return;
        }
        // Any release ends it; the pressed item may have been reindexed or removed.
        if (!pressed)
            motion.retarget(0);
    }

    function dx(item: int): real {
        return active ? (shifts[item]?.x ?? 0) * motion.value : 0;
    }

    function dw(item: int): real {
        return active ? (shifts[item]?.w ?? 0) * motion.value : 0;
    }

    property SpringMotion motion: SpringMotion {
        enabled: root.animated
        stiffness: root.spring.stiffness
        damping: root.spring.damping
    }
}
