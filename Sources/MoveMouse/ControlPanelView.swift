import SwiftUI

struct ControlPanelView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    private var theme: MoveMouseTheme {
        MoveMouseTheme(colorScheme: colorScheme)
    }

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

                PanelCard(title: "Session", systemImage: "power", theme: theme) {
                    Toggle(isOn: runningBinding) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appState.runningLabel)
                                .font(.headline)
                            Text(appState.runningSummary)
                                .font(.subheadline)
                                .foregroundStyle(theme.secondaryText)
                        }
                    }
                    .toggleStyle(.switch)

                    Divider()

                    Toggle("Keep display awake", isOn: $appState.keepDisplayAwake)
                    Toggle("Keep system awake", isOn: $appState.keepSystemAwake)

                    HStack {
                        Spacer()

                        Text(appState.protectionSummary)
                            .font(.caption)
                            .foregroundStyle(theme.secondaryText)
                    }
                }

                PanelCard(title: "Status", systemImage: appState.statusSymbol, theme: theme) {
                    Text(appState.statusMessage)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(appState.scheduleStatusSummary)
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                }

                PanelCard(title: "Schedule", systemImage: "clock", theme: theme) {
                    Toggle("Limit to active hours", isOn: $appState.scheduleEnabled)

                    if appState.scheduleEnabled {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("From")
                                    .font(.caption)
                                    .foregroundStyle(theme.secondaryText)
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
                                    .foregroundStyle(theme.secondaryText)
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
                        .foregroundStyle(theme.secondaryText)
                }

                footer
            }
            .padding(18)
            .foregroundStyle(theme.primaryText)
        }
        .tint(theme.accent)
        .frame(width: 360, height: 560)
        .background(theme.backgroundGradient)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("MoveMouse")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryText)

                Text("A tiny macOS menu bar utility that keeps your Mac awake without moving the pointer.")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Label(appState.isRunning ? "On" : "Off", systemImage: appState.isRunning ? "bolt.fill" : "pause.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.primaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    theme.badgeFill(isRunning: appState.isRunning),
                    in: Capsule()
                )
        }
    }

    private var footer: some View {
        PanelCard(title: "App Store Path", systemImage: "checkmark.shield", theme: theme) {
            Text("This version avoids Accessibility permission and synthetic cursor movement, which is a safer direction for Mac App Store distribution.")
                .font(.footnote)
                .foregroundStyle(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

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
    let theme: MoveMouseTheme
    let content: Content

    init(title: String, systemImage: String, theme: MoveMouseTheme, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.theme = theme
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            content
        }
        .padding(14)
        .background(theme.cardFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.cardStroke, lineWidth: 1)
        )
        .shadow(color: theme.cardShadow, radius: 18, y: 8)
    }
}

private struct MoveMouseTheme {
    let colorScheme: ColorScheme

    var primaryText: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.96)
        default:
            return Color(red: 0.14, green: 0.17, blue: 0.21)
        }
    }

    var secondaryText: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.72)
        default:
            return Color(red: 0.35, green: 0.39, blue: 0.45)
        }
    }

    var accent: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.41, green: 0.72, blue: 0.98)
        default:
            return Color(red: 0.12, green: 0.45, blue: 0.93)
        }
    }

    var backgroundGradient: LinearGradient {
        switch colorScheme {
        case .dark:
            return LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.12, blue: 0.16),
                    Color(red: 0.07, green: 0.17, blue: 0.25),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.95, blue: 0.89),
                    Color(red: 0.91, green: 0.96, blue: 0.98),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var cardFill: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.08)
        default:
            return Color.white.opacity(0.72)
        }
    }

    var cardStroke: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.10)
        default:
            return Color.black.opacity(0.06)
        }
    }

    var cardShadow: Color {
        switch colorScheme {
        case .dark:
            return Color.black.opacity(0.28)
        default:
            return Color(red: 0.48, green: 0.41, blue: 0.22).opacity(0.10)
        }
    }

    func badgeFill(isRunning: Bool) -> Color {
        switch (colorScheme, isRunning) {
        case (.dark, true):
            return Color.green.opacity(0.28)
        case (.dark, false):
            return Color.orange.opacity(0.26)
        case (_, true):
            return Color.green.opacity(0.18)
        default:
            return Color.orange.opacity(0.18)
        }
    }
}
