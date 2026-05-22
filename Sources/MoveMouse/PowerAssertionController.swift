import Foundation

final class PowerAssertionController {
    private struct Configuration: Equatable {
        let isActive: Bool
        let keepDisplayAwake: Bool
        let keepSystemAwake: Bool
    }

    private var activityToken: NSObjectProtocol?
    private var currentConfiguration = Configuration(
        isActive: false,
        keepDisplayAwake: false,
        keepSystemAwake: false
    )

    func update(isActive: Bool, keepDisplayAwake: Bool, keepSystemAwake: Bool) {
        let nextConfiguration = Configuration(
            isActive: isActive,
            keepDisplayAwake: keepDisplayAwake,
            keepSystemAwake: keepSystemAwake
        )

        guard nextConfiguration != currentConfiguration else {
            return
        }

        if let activityToken {
            ProcessInfo.processInfo.endActivity(activityToken)
            self.activityToken = nil
        }

        if isActive, keepDisplayAwake || keepSystemAwake {
            var options: ProcessInfo.ActivityOptions = []

            if keepDisplayAwake {
                options.insert(.idleDisplaySleepDisabled)
            }

            if keepSystemAwake {
                options.insert(.idleSystemSleepDisabled)
            }

            activityToken = ProcessInfo.processInfo.beginActivity(
                options: options,
                reason: "MoveMouse is keeping the Mac awake without moving the pointer."
            )
        }

        currentConfiguration = nextConfiguration
    }
}
