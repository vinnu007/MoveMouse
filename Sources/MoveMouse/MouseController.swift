import AppKit
import ApplicationServices
import CoreGraphics

struct MouseController {
    func hasAccessibilityPermission(prompt: Bool) -> Bool {
        guard prompt else {
            return AXIsProcessTrusted()
        }

        let promptKey = "AXTrustedCheckOptionPrompt"
        let options = [promptKey: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    var idleSeconds: TimeInterval {
        let eventTypes: [CGEventType] = [
            .mouseMoved,
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown,
            .scrollWheel,
            .keyDown,
        ]

        let samples = eventTypes
            .map { CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0) }
            .filter(\.isFinite)

        return samples.min() ?? 0
    }

    func jiggle(distance: CGFloat, restorePosition: Bool) -> Bool {
        guard let eventSource = CGEventSource(stateID: .combinedSessionState) else {
            return false
        }

        let startPoint = NSEvent.mouseLocation
        let screenFrame = NSScreen.screens.first(where: { $0.frame.contains(startPoint) })?.frame
            ?? NSScreen.main?.frame
            ?? CGRect(x: 0, y: 0, width: 1024, height: 768)
        let horizontalDirection: CGFloat = startPoint.x < screenFrame.midX ? 1 : -1
        let offset = max(distance, 1) * horizontalDirection
        let clampedX = min(
            max(startPoint.x + offset, screenFrame.minX + 2),
            screenFrame.maxX - 2
        )
        let movedPoint = CGPoint(x: clampedX, y: startPoint.y)

        guard postMouseMove(using: eventSource, to: movedPoint) else {
            return false
        }

        if restorePosition {
            guard postMouseMove(using: eventSource, to: startPoint) else {
                return false
            }
        }

        return true
    }

    private func postMouseMove(using eventSource: CGEventSource, to point: CGPoint) -> Bool {
        // Synthetic mouse-moved events keep the cursor nearly still while still refreshing idle state.
        guard let moveEvent = CGEvent(
            mouseEventSource: eventSource,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else {
            return false
        }

        moveEvent.post(tap: .cghidEventTap)
        return true
    }
}
