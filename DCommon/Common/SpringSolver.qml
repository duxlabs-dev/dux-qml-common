pragma Singleton

import QtQuick
import Quickshell
import "SpringMath.js" as SpringMath

Singleton {
    readonly property var runtime: Quickshell
    readonly property bool nativeAvailable: typeof runtime.springCoefficients === "function"
    readonly property bool frameLockAvailable: typeof runtime.springFrameCoefficients === "function"

    function coefficients(stiffness, damping, mass, seconds) {
        if (nativeAvailable)
            return runtime.springCoefficients(stiffness, damping, mass, seconds);
        return SpringMath.coefficients(stiffness, damping, mass, seconds);
    }

    function frameCoefficients(stiffness, damping, mass, frameTime) {
        if (frameLockAvailable)
            return runtime.springFrameCoefficients(stiffness, damping, mass, frameTime);
        return coefficients(stiffness, damping, mass, frameTime);
    }
}
