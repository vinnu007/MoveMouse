import AppKit
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var isRunning = false
    @Published var intervalSeconds: Double {
        didSet {
            defaults.set(intervalSeconds, forKey: DefaultsKey.intervalSeconds)
            refreshStatus(now: .now)
        }
    }
    @Published var movementPixels: Double {
        didSet {
            defaults.set(movementPixels, forKey: DefaultsKey.movementPixels)
            refreshStatus(now: .now)
        }
    }
    @Published var restoreCursorPosition: Bool {
        didSet {
            defaults.set(restoreCursorPosition, forKey: DefaultsKey.restoreCursorPosition)
        }
    }
    @Published var preventSleep: Bool {
        didSet {
            defaults.set(preventSleep, forKey: DefaultsKey.preventSleep)
            updatePowerAssertion()
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
    @Published private(set) var accessibilityGranted: Bool
    @Published private(set) var idleSeconds: TimeInterval = 0
    @Published private(set) var lastJiggleAt: Date?
    @Published private(set) var statusMessage = "Ready to keep your Mac awake."

    private let defaults: UserDefaults
    private let mouseController: MouseController
    private let powerController: PowerAssertionController
    private let jigglePolicy = JigglePolicy()
    private let timeFormatter: DateFormatter
    private var timer: Timer?

    init(
        defaults: UserDefaults = .standard,
        mouseController: MouseController = MouseController(),
        powerController: PowerAssertionController = PowerAssertionController()
    ) {
        self.defaults = defaults
        self.mouseController = mouseController
        self.powerController = powerController
        self.intervalSeconds = Self.storedDouble(forKey: DefaultsKey.intervalSeconds, in: defaults, fallback: 60)
        self.movementPixels = Self.storedDouble(forKey: DefaultsKey.movementPixels, in: defaults, fallback: 2)
        self.restoreCursorPosition = Self.storedBool(forKey: DefaultsKey.restoreCursorPosition, in: defaults, fallback: true)
        self.preventSleep = Self.storedBool(forKey: DefaultsKey.preventSleep, in: defaults, fallback: true)
        self.scheduleEnabled = Self.storedBool(forKey: DefaultsKey.scheduleEnabled, in: defaults, fallback: false)
        self.startHour = Self.storedInt(forKey: DefaultsKey.startHour, in: defaults, fallback: 9)
        self.endHour = Self.storedInt(forKey: DefaultsKey.endHour, in: defaults, fallback: 18)
        self.accessibilityGranted = mouseController.hasAccessibilityPermission(prompt: false)
        self.timeFormatter = Self.makeTimeFormatter()
        refreshStatus(now: .now)
    }

    var menuBarSymbol: String {
        isRunning ? "cursorarrow.motionlines" : "cursorarrow"
    }

    var runningLabel: String {
        isRunning ? "MoveMouse is active" : "MoveMouse is paused"
    }

    var runningSummary: String {
        isRunning ? "Your Mac will stay awake after idle time is detected." : "Turn it on whenever you want a hands-free keep-awake session."
    }

    var scheduleSummary: String {
        schedule.summary()
    }

    var lastJiggleDescription: String? {
        guard let lastJiggleAt else {
            return nil
        }

        return "Last nudge at \(timeFormatter.string(from: lastJiggleAt))"
    }

    var statusSymbol: String {
        if !accessibilityGranted {
            return "hand.raised.fill"
        }

        return isRunning ? "bolt.fill" : "pause.circle.fill"
    }

    func setRunning(_ shouldRun: Bool) {
        guard shouldRun != isRunning else {
            return
        }

        if shouldRun {
            accessibilityGranted = mouseController.hasAccessibilityPermission(prompt: true)

            guard accessibilityGranted else {
                statusMessage = "Accessibility access is required before MoveMouse can control the cursor."
                return
            }

            isRunning = true
            startTimer()
            updatePowerAssertion()
            refreshStatus(now: .now)
            return
        }

        isRunning = false
        stopTimer()
        updatePowerAssertion()
        refreshStatus(now: .now)
    }

    func requestAccessibilityAccess() {
        accessibilityGranted = mouseController.hasAccessibilityPermission(prompt: true)
        refreshStatus(now: .now)
    }

    func quit() {
        NSApplication.shared.terminate(nil)
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

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick(now: .now)
            }
        }
        timer.tolerance = 0.2

        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        tick(now: .now)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func syncSystemState() {
        accessibilityGranted = mouseController.hasAccessibilityPermission(prompt: false)
        idleSeconds = mouseController.idleSeconds
    }

    private func tick(now: Date) {
        syncSystemState()

        switch jigglePolicy.eligibility(
            isRunning: isRunning,
            hasAccessibilityPermission: accessibilityGranted,
            isWithinSchedule: schedule.contains(now),
            idleSeconds: idleSeconds,
            intervalSeconds: intervalSeconds,
            lastJiggleAt: lastJiggleAt,
            now: now
        ) {
        case .ready:
            let didJiggle = mouseController.jiggle(
                distance: CGFloat(movementPixels),
                restorePosition: restoreCursorPosition
            )

            if didJiggle {
                lastJiggleAt = now
                statusMessage = "Cursor nudged at \(timeFormatter.string(from: now))."
            } else {
                accessibilityGranted = mouseController.hasAccessibilityPermission(prompt: false)
                statusMessage = "MoveMouse could not post a cursor event. Recheck Accessibility access."
            }
        case .stopped:
            statusMessage = "Paused and ready when you are."
        case .missingPermission:
            statusMessage = "Grant Accessibility access so MoveMouse can control the pointer."
        case .outsideSchedule:
            statusMessage = "Outside active hours. Current schedule: \(scheduleSummary)."
        case .waitingForIdle(let secondsRemaining):
            statusMessage = "Watching for \(Self.secondsText(secondsRemaining)) of idle time."
        case .waitingForInterval(let secondsRemaining):
            statusMessage = "Next nudge in about \(Self.secondsText(secondsRemaining))."
        }
    }

    private func refreshStatus(now: Date) {
        syncSystemState()

        switch jigglePolicy.eligibility(
            isRunning: isRunning,
            hasAccessibilityPermission: accessibilityGranted,
            isWithinSchedule: schedule.contains(now),
            idleSeconds: idleSeconds,
            intervalSeconds: intervalSeconds,
            lastJiggleAt: lastJiggleAt,
            now: now
        ) {
        case .ready:
            statusMessage = "Ready for the next idle nudge."
        case .stopped:
            statusMessage = "Paused and ready when you are."
        case .missingPermission:
            statusMessage = "Grant Accessibility access so MoveMouse can control the pointer."
        case .outsideSchedule:
            statusMessage = "Outside active hours. Current schedule: \(scheduleSummary)."
        case .waitingForIdle(let secondsRemaining):
            statusMessage = "Watching for \(Self.secondsText(secondsRemaining)) of idle time."
        case .waitingForInterval(let secondsRemaining):
            statusMessage = "Next nudge in about \(Self.secondsText(secondsRemaining))."
        }
    }

    private func updatePowerAssertion() {
        powerController.update(isActive: isRunning && preventSleep)
    }

    private static func storedDouble(forKey key: String, in defaults: UserDefaults, fallback: Double) -> Double {
        defaults.object(forKey: key) == nil ? fallback : defaults.double(forKey: key)
    }

    private static func storedBool(forKey key: String, in defaults: UserDefaults, fallback: Bool) -> Bool {
        defaults.object(forKey: key) == nil ? fallback : defaults.bool(forKey: key)
    }

    private static func storedInt(forKey key: String, in defaults: UserDefaults, fallback: Int) -> Int {
        defaults.object(forKey: key) == nil ? fallback : defaults.integer(forKey: key)
    }

    private static func makeTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }

    private static func secondsText(_ interval: TimeInterval) -> String {
        "\(Int(interval.rounded(.up))) sec"
    }
}

private enum DefaultsKey {
    static let intervalSeconds = "intervalSeconds"
    static let movementPixels = "movementPixels"
    static let restoreCursorPosition = "restoreCursorPosition"
    static let preventSleep = "preventSleep"
    static let scheduleEnabled = "scheduleEnabled"
    static let startHour = "startHour"
    static let endHour = "endHour"
}
