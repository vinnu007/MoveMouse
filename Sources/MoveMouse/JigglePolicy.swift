import Foundation

struct ActiveSchedule: Equatable {
    var isEnabled: Bool
    var startHour: Int
    var endHour: Int

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        guard isEnabled else {
            return true
        }

        if startHour == endHour {
            return true
        }

        let currentHour = calendar.component(.hour, from: date)

        if startHour < endHour {
            return currentHour >= startHour && currentHour < endHour
        }

        return currentHour >= startHour || currentHour < endHour
    }

    func summary(calendar: Calendar = .current) -> String {
        guard isEnabled else {
            return "Always active"
        }

        if startHour == endHour {
            return "Always active"
        }

        return "\(Self.label(for: startHour, calendar: calendar)) to \(Self.label(for: endHour, calendar: calendar))"
    }

    static func label(for hour: Int, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        let date = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: hour)) ?? .now
        return formatter.string(from: date)
    }
}

enum JiggleEligibility: Equatable {
    case stopped
    case missingPermission
    case outsideSchedule
    case waitingForIdle(secondsRemaining: TimeInterval)
    case waitingForInterval(secondsRemaining: TimeInterval)
    case ready
}

struct JigglePolicy {
    func eligibility(
        isRunning: Bool,
        hasAccessibilityPermission: Bool,
        isWithinSchedule: Bool,
        idleSeconds: TimeInterval,
        intervalSeconds: TimeInterval,
        lastJiggleAt: Date?,
        now: Date
    ) -> JiggleEligibility {
        guard isRunning else {
            return .stopped
        }

        guard hasAccessibilityPermission else {
            return .missingPermission
        }

        guard isWithinSchedule else {
            return .outsideSchedule
        }

        guard idleSeconds >= intervalSeconds else {
            return .waitingForIdle(secondsRemaining: intervalSeconds - idleSeconds)
        }

        if let lastJiggleAt {
            let elapsed = now.timeIntervalSince(lastJiggleAt)

            if elapsed < intervalSeconds {
                return .waitingForInterval(secondsRemaining: intervalSeconds - elapsed)
            }
        }

        return .ready
    }
}
