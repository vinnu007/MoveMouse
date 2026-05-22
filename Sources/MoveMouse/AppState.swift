import AppKit
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var isRunning = false
    @Published var keepDisplayAwake: Bool {
        didSet {
            defaults.set(keepDisplayAwake, forKey: DefaultsKey.keepDisplayAwake)
            refreshStatus(now: .now)
        }
    }
    @Published var keepSystemAwake: Bool {
        didSet {
            defaults.set(keepSystemAwake, forKey: DefaultsKey.keepSystemAwake)
            refreshStatus(now: .now)
        }
    }
    @Published var scheduleEnabled: Bool {
        didSet {
            defaults.set(scheduleEnabled, forKey: DefaultsKey.scheduleEnabled)
            refreshStatus(now: .now)
        }
    }
    @Published var startHour: Int {
        didSet {
            defaults.set(startHour, forKey: DefaultsKey.startHour)
            refreshStatus(now: .now)
        }
    }
    @Published var endHour: Int {
        didSet {
            defaults.set(endHour, forKey: DefaultsKey.endHour)
            refreshStatus(now: .now)
        }
    }
    @Published private(set) var isWithinSchedule = true
    @Published private(set) var statusMessage = "Ready to keep your Mac awake."

    private let defaults: UserDefaults
    private let powerController: PowerAssertionController
    private let keepAwakePolicy = KeepAwakePolicy()
    private var timer: Timer?

    init(
        defaults: UserDefaults = .standard,
        powerController: PowerAssertionController = PowerAssertionController()
    ) {
        self.defaults = defaults
        self.powerController = powerController
        self.keepDisplayAwake = Self.storedBool(forKey: DefaultsKey.keepDisplayAwake, in: defaults, fallback: true)
        self.keepSystemAwake = Self.storedBool(forKey: DefaultsKey.keepSystemAwake, in: defaults, fallback: true)
        self.scheduleEnabled = Self.storedBool(forKey: DefaultsKey.scheduleEnabled, in: defaults, fallback: false)
        self.startHour = Self.storedInt(forKey: DefaultsKey.startHour, in: defaults, fallback: 9)
        self.endHour = Self.storedInt(forKey: DefaultsKey.endHour, in: defaults, fallback: 18)
        startTimer()
        refreshStatus(now: .now)
    }

    var menuBarSymbol: String {
        isActivelyKeepingAwake ? "bolt.badge.clock.fill" : (isRunning ? "bolt.circle" : "pause.circle")
    }

    var runningLabel: String {
        isRunning ? "Keep Awake is active" : "Keep Awake is paused"
    }

    var runningSummary: String {
        isRunning
            ? "MoveMouse is using macOS power assertions to keep your Mac awake."
            : "Turn it on whenever you want to stop your Mac from sleeping."
    }

    var scheduleSummary: String {
        schedule.summary()
    }

    var protectionSummary: String {
        switch (keepDisplayAwake, keepSystemAwake) {
        case (true, true):
            return "Keeping both the display and system awake."
        case (true, false):
            return "Keeping only the display awake."
        case (false, true):
            return "Keeping only the system awake."
        case (false, false):
            return "No keep-awake option is currently selected."
        }
    }

    var scheduleStatusSummary: String {
        scheduleEnabled
            ? (isWithinSchedule ? "Inside active hours" : "Outside active hours")
            : "Schedule disabled"
    }

    var statusSymbol: String {
        switch currentEligibility {
        case .active:
            return "bolt.fill"
        case .outsideSchedule:
            return "clock.badge.exclamationmark"
        case .nothingSelected:
            return "exclamationmark.triangle.fill"
        case .stopped:
            return "pause.circle.fill"
        }
    }

    func setRunning(_ shouldRun: Bool) {
        guard shouldRun != isRunning else {
            return
        }

        isRunning = shouldRun
        refreshStatus(now: .now)
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    private var currentEligibility: KeepAwakeEligibility {
        keepAwakePolicy.eligibility(
            isRunning: isRunning,
            isWithinSchedule: isWithinSchedule,
            keepDisplayAwake: keepDisplayAwake,
            keepSystemAwake: keepSystemAwake
        )
    }

    private var isActivelyKeepingAwake: Bool {
        currentEligibility == .active
    }

    private var schedule: ActiveSchedule {
        ActiveSchedule(
            isEnabled: scheduleEnabled,
            startHour: startHour,
            endHour: endHour
        )
    }

    private func startTimer() {
        stopTimer()

        let timer = Timer(timeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick(now: .now)
            }
        }
        timer.tolerance = 1

        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        tick(now: .now)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick(now: Date) {
        refreshStatus(now: now)
    }

    private func refreshStatus(now: Date) {
        isWithinSchedule = schedule.contains(now)

        switch currentEligibility {
        case .active:
            statusMessage = protectionSummary
        case .stopped:
            statusMessage = "Paused and ready when you are."
        case .nothingSelected:
            statusMessage = "Enable at least one keep-awake option to prevent sleep."
        case .outsideSchedule:
            statusMessage = "Outside active hours. Current schedule: \(scheduleSummary)."
        }

        updatePowerAssertion()
    }

    private func updatePowerAssertion() {
        powerController.update(
            isActive: isActivelyKeepingAwake,
            keepDisplayAwake: keepDisplayAwake,
            keepSystemAwake: keepSystemAwake
        )
    }

    private static func storedBool(forKey key: String, in defaults: UserDefaults, fallback: Bool) -> Bool {
        defaults.object(forKey: key) == nil ? fallback : defaults.bool(forKey: key)
    }

    private static func storedInt(forKey key: String, in defaults: UserDefaults, fallback: Int) -> Int {
        defaults.object(forKey: key) == nil ? fallback : defaults.integer(forKey: key)
    }

}

private enum DefaultsKey {
    static let keepDisplayAwake = "keepDisplayAwake"
    static let keepSystemAwake = "keepSystemAwake"
    static let scheduleEnabled = "scheduleEnabled"
    static let startHour = "startHour"
    static let endHour = "endHour"
}
