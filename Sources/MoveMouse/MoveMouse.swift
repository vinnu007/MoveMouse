import AppKit
import SwiftUI

@main
struct MoveMouseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("MoveMouse", systemImage: appState.menuBarSymbol) {
            ControlPanelView()
                .environmentObject(appState)
                .frame(width: 360)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
