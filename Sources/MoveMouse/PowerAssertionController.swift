import Foundation

final class PowerAssertionController {
    private var activityToken: NSObjectProtocol?

    func update(isActive: Bool) {
        if isActive {
            guard activityToken == nil else {
                return
            }

            activityToken = ProcessInfo.processInfo.beginActivity(
                options: [
                    .idleDisplaySleepDisabled,
                    .idleSystemSleepDisabled,
                ],
                reason: "MoveMouse is keeping the Mac awake."
            )
        } else if let activityToken {
            ProcessInfo.processInfo.endActivity(activityToken)
            self.activityToken = nil
        }
    }
}
