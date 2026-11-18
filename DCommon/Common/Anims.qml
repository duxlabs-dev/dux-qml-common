pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    readonly property int durShort: 200
    readonly property int durMed: 450
    readonly property int durLong: 600

    readonly property int slidePx: 80
}
