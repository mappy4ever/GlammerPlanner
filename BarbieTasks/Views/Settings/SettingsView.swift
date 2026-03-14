import SwiftUI

struct SettingsView: View {
    @Environment(Store.self) private var store
    @Environment(AppSettings.self) private var settings
    @EnvironmentObject private var updaterService: UpdaterService

    var body: some View {
        TabView {
            generalTab.tabItem { Label("General", systemImage: "gear") }
            pomodoroTab.tabItem { Label("Focus", systemImage: "timer") }
            integrationsTab.tabItem { Label("Integrations", systemImage: "link") }
            dataTab.tabItem { Label("Data", systemImage: "externaldrive") }
        }
        .frame(width: 480, height: 520)
    }

    // MARK: - General

    private var generalTab: some View {
        Form {
            Section("Theme") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(AppThemeId.allCases) { theme in
                        let isSelected = settings.appTheme == theme.rawValue
                        Button {
                            settings.appTheme = theme.rawValue
                        } label: {
                            HStack(spacing: 10) {
                                // Color preview circles — show full palette rainbow
                                HStack(spacing: -3) {
                                    Circle().fill(theme.palette.primary)
                                        .frame(width: 14, height: 14)
                                    Circle().fill(theme.palette.priorityHigh)
                                        .frame(width: 14, height: 14)
                                    Circle().fill(theme.palette.accent)
                                        .frame(width: 14, height: 14)
                                    Circle().fill(theme.palette.priorityMed)
                                        .frame(width: 14, height: 14)
                                    Circle().fill(theme.palette.priorityLow)
                                        .frame(width: 14, height: 14)
                                }

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(theme.name)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(isSelected ? theme.palette.primary : Color.primary)
                                    Text(theme.tagline)
                                        .font(.system(size: 9, weight: .medium, design: .rounded))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(theme.palette.primary)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? theme.palette.primary.opacity(0.1) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? theme.palette.primary : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Quote Style") {
                Picker("Celebration quotes", selection: Binding(
                    get: { settings.quoteStyle },
                    set: { settings.quoteStyle = $0 }
                )) {
                    Text("Match theme").tag("match_theme")
                    ForEach(AppThemeId.allCases) { theme in
                        Text(theme.name).tag(theme.rawValue)
                    }
                }
                Text("Choose which quote style plays when you complete tasks.")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Section("Appearance") {
                Picker("Theme", selection: Binding(
                    get: { settings.appearance },
                    set: { settings.appearance = $0 }
                )) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)

                Toggle("Reduce animations", isOn: Binding(
                    get: { settings.reduceAnimations },
                    set: { settings.reduceAnimations = $0 }
                ))
            }

            Section("Completion") {
                Toggle("Show completion timestamp", isOn: Binding(
                    get: { settings.autoCompletionTimestamp },
                    set: { settings.autoCompletionTimestamp = $0 }
                ))
            }

            Section("Task Details") {
                Toggle("Auto-open detail panel on click", isOn: Binding(
                    get: { settings.autoOpenDetail },
                    set: { settings.autoOpenDetail = $0 }
                ))
                Text("When off, click the detail button on a task to open the side panel.")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Section("Daily Goal") {
                Stepper("Target: \(store.profile.dailyGoal) tasks/day",
                        value: Binding(
                            get: { store.profile.dailyGoal },
                            set: { store.profile.dailyGoal = $0; store.save() }
                        ),
                        in: 1...50)
                Text("Get a special celebration when you hit your daily target.")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Section("Calendar") {
                Picker("Week starts on", selection: Binding(
                    get: { settings.calendarStartDay },
                    set: { settings.calendarStartDay = $0 }
                )) {
                    Text("Sunday").tag(1)
                    Text("Monday").tag(2)
                    Text("Saturday").tag(7)
                }
            }

            Section("Notifications") {
                Toggle("Enable notifications", isOn: Binding(
                    get: { settings.notificationsEnabled },
                    set: { settings.notificationsEnabled = $0 }
                ))

                Picker("Default reminder", selection: Binding(
                    get: { settings.defaultReminderOffset },
                    set: { settings.defaultReminderOffset = $0 }
                )) {
                    Text("None").tag(0)
                    Text("5 minutes before").tag(5)
                    Text("15 minutes before").tag(15)
                    Text("30 minutes before").tag(30)
                    Text("1 hour before").tag(60)
                }
            }
        }
        .formStyle(.grouped)
        .font(.system(size: 13, design: .rounded))
    }

    // MARK: - Pomodoro

    private var pomodoroTab: some View {
        Form {
            Section("Durations") {
                Stepper("Focus: \(settings.pomWorkMinutes) min",
                        value: Binding(get: { settings.pomWorkMinutes }, set: { settings.pomWorkMinutes = $0 }),
                        in: 5...120, step: 5)

                Stepper("Short break: \(settings.pomShortBreak) min",
                        value: Binding(get: { settings.pomShortBreak }, set: { settings.pomShortBreak = $0 }),
                        in: 1...30)

                Stepper("Long break: \(settings.pomLongBreak) min",
                        value: Binding(get: { settings.pomLongBreak }, set: { settings.pomLongBreak = $0 }),
                        in: 5...60, step: 5)

                Stepper("Sessions before long break: \(settings.pomSessionsBeforeLong)",
                        value: Binding(get: { settings.pomSessionsBeforeLong }, set: { settings.pomSessionsBeforeLong = $0 }),
                        in: 2...8)
            }

            Section("Behavior") {
                Toggle("Auto-start breaks", isOn: Binding(
                    get: { settings.pomAutoStartBreak },
                    set: { settings.pomAutoStartBreak = $0 }
                ))
            }
        }
        .formStyle(.grouped)
        .font(.system(size: 13, design: .rounded))
    }

    // MARK: - Integrations

    private var integrationsTab: some View {
        Form {
            Section("Apple Calendar") {
                Toggle("Show calendar events", isOn: Binding(
                    get: { settings.calendarSyncEnabled },
                    set: {
                        settings.calendarSyncEnabled = $0
                        if $0 { Task { await CalendarService.shared.requestAccess() } }
                    }
                ))
                Text("Events from your Apple Calendar will appear in the Calendar view.")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Section("Apple Reminders") {
                Toggle("Enable Reminders sync", isOn: Binding(
                    get: { settings.remindersSyncEnabled },
                    set: {
                        settings.remindersSyncEnabled = $0
                        if $0 { Task { await RemindersService.shared.requestAccess() } }
                    }
                ))

                if settings.remindersSyncEnabled && RemindersService.shared.hasAccess {
                    ForEach(RemindersService.shared.reminderLists, id: \.calendarIdentifier) { list in
                        Button("Import from \"\(list.title)\"") {
                            Task {
                                let imported = await RemindersService.shared.importReminders(from: list)
                                await MainActor.run { store.importReminders(imported) }
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .font(.system(size: 13, design: .rounded))
    }

    // MARK: - Data

    private var dataTab: some View {
        Form {
            Section("Export") {
                Button("Export as JSON...") {
                    guard let data = store.exportJSON() else { return }
                    let panel = NSSavePanel()
                    panel.allowedContentTypes = [.json]
                    panel.nameFieldStringValue = "GlammerPlanner-Backup.json"
                    if panel.runModal() == .OK, let url = panel.url {
                        try? data.write(to: url)
                    }
                }
            }

            Section("Import") {
                Button("Import from JSON...") {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.json]
                    if panel.runModal() == .OK, let url = panel.url,
                       let data = try? Data(contentsOf: url) {
                        let success = store.importJSON(data)
                        if !success {
                            // Could show an alert
                        }
                    }
                }

                Text("Importing will replace all current data.")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Section("Storage") {
                let count = store.tasks.count
                let projects = store.projects.count
                Text("\(count) tasks, \(projects) projects")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Section("About") {
                HStack {
                    Text("Small Wins")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Spacer()
                    if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                       let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
                        Text("Version \(version) (\(build))")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle("Automatically check for updates", isOn: Binding(
                    get: { updaterService.automaticallyChecksForUpdates },
                    set: { updaterService.automaticallyChecksForUpdates = $0 }
                ))

                Button("Check for Updates...") {
                    updaterService.checkForUpdates()
                }
                .disabled(!updaterService.canCheckForUpdates)

                Button("Show Onboarding") {
                    settings.hasCompletedOnboarding = false
                }
            }
        }
        .formStyle(.grouped)
        .font(.system(size: 13, design: .rounded))
    }
}
