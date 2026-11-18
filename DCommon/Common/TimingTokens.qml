import QtQuick

QtObject {
    readonly property int frame: 16
    // Frame-driven ticks measured about 2.5x the GPU of this cap (#4282).
    readonly property int cappedTick: 16
    readonly property int second: 1000
    readonly property int minute: 60000

    readonly property int focusRetryDelay: 150
    readonly property int holdHintTimeout: 2000
    readonly property int authFeedbackHold: 4000
    readonly property int calendarRefreshDebounce: 400
    readonly property int dropdownSearchDebounce: 50
    readonly property int locationSearchDebounce: 500
    readonly property int locationDropdownHideDelay: 200
    readonly property int blurSettleRepeatDelay: 96
    readonly property int wheelStepCooldown: 100
}
