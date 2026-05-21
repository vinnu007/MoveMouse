import SwiftUI

struct ControlPanelView: View {
    @EnvironmentObject private var appState: AppState

    private var runningBinding: Binding<Bool> {
        Binding(
            get: { appState.isRunning },
            set: { appState.setRunning($0) }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                PanelCard(title: "Session", systemImage: "power") {
                    Toggle(isOn: runningBinding) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appState.runningLabel)
                                .font(.headline)
                            Text(appState.runningSummary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.switch)

                    Divider()

                    Toggle("Prevent display and system sleep", isOn: $appState.preventSleep)
                }

                PanelCard(title: "Idle Trigger", systemImage: "timer") {
                    HStack {
                        Text("Jiggle after idle")
                        Spacer()
                        Text("\(Int(appState.intervalSeconds)) sec")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $appState.intervalSeconds, in: 30...600, step: 15)
                }

                PanelCard(title: "Cursor Motion", systemImage: "arrow.left.and.right") {
                    HStack {
                        Text("Movement distance")
                        Spacer()
                        Text("\(Int(appState.movementPixels)) px")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $appState.movementPixels, in: 1...10, step: 1)

                    Toggle("Return pointer to original spot", isOn: $appState.restoreCursorPosition)
                }

                PanelCard(title: "Schedule", systemImage: "clock") {
                    Toggle("Limit to active hours", isOn: $appState.scheduleEnabled)

                    if appState.scheduleEnabled {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("From")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Picker("Start hour", selection: $appState.startHour) {
                                    ForEach(0..<24, id: \.self) { hour in
                                        Text(ActiveSchedule.label(for: hour)).tag(hour)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("To")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Picker("End hour", selection: $appState.endHour) {
                                    ForEach(0..<24, id: \.self) { hour in
                                        Text(ActiveSchedule.label(for: hour)).tag(hour)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                            }
                        }
                    }

                    Text(appState.scheduleSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !appState.accessibilityGranted {
                    PanelCard(title: "Permission", systemImage: "hand.raised.fill") {
                        Text("macOS needs Accessibility permission before MoveMouse can post cursor movement events.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("Request Accessibility Access") {
                            appState.requestAccessibilityAccess()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                footer
            }
            .padding(18)
        }
        .frame(width: 360, height: 560)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.95, blue: 0.89),
                    Color(red: 0.91, green: 0.96, blue: 0.98),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("MoveMouse")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))

                Text("A tiny macOS menu bar utility that nudges the cursor only after your Mac has gone idle.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Label(appState.isRunning ? "On" : "Off", systemImage: appState.isRunning ? "bolt.fill" : "pause.fill")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    (appState.isRunning ? Color.green : Color.orange).opacity(0.18),
                    in: Capsule()
                )
        }
    }

    private var footer: some View {
        PanelCard(title: "Status", systemImage: appState.statusSymbol) {
            Text(appState.statusMessage)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)

            if let lastJiggleDescription = appState.lastJiggleDescription {
                Text(lastJiggleDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()

                Button("Quit") {
                    appState.quit()
                }
            }
        }
    }
}

private struct PanelCard<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content

    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            content
        }
        .padding(14)
        .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}
