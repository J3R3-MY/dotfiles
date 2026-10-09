pragma Singleton
import QtQuick
import Quickshell

// Shared motion curves so everything moves the same way.
// "emphasized" is the Material 3 emphasized-decelerate curve that Serpantinum
// also leans on; "spring" overshoots slightly for the island morph.
Singleton {
    readonly property list<real> emphasized: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    readonly property list<real> standard: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property list<real> spring: [0.34, 1.36, 0.64, 1.0, 1.0, 1.0]

    readonly property int fast: 180
    readonly property int normal: 320
    readonly property int slow: 480
}
