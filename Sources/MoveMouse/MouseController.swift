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
        guard
            let eventSource = CGEventSource(stateID: .combinedSessionState),
            let currentEvent = CGEvent(source: eventSource)
        else {
            return false
        }

        let currentMouseLocation = NSEvent.mouseLocation
        let screenFrame = NSScreen.screens.first(where: { $0.frame.contains(currentMouseLocation) })?.frame
            ?? NSScreen.main?.frame
            ?? CGRect(x: 0, y: 0, width: 1024, height: 768)
        let horizontalDirection: CGFloat = currentMouseLocation.x < screenFrame.midX ? 1 : -1
        let offset = max(distance, 1) * horizontalDirection
        let clampedX = min(
            max(currentEvent.location.x + offset, screenFrame.minX + 2),
            screenFrame.maxX - 2
        )
        let movedPoint = CGPoint(x: clampedX, y: currentEvent.location.y)

        // Synthetic mouse-moved events keep the cursor nearly still while still refreshing idle state.
        guard let moveEvent = CGEvent(
            mouseEventSource: eventSource,
            mouseType: .mouseMoved,
            mouseCursorPosition: movedPoint,
            mouseButton: .left
        ) else {
            return false
        }

        moveEvent.post(tap: .cghidEventTap)

        if restorePosition {
            guard let restoreEvent = CGEvent(
                mouseEventSource: eventSource,
                mouseType: .mouseMoved,
                mouseCursorPosition: currentEvent.location,
                mouseButton: .left
            ) else {
                return false
            }

            restoreEvent.post(tap: .cghidEventTap)
        }

        return true
    }
}
