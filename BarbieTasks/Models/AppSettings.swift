import Foundation
import SwiftUI

@Observable
final class AppSettings {
    // Appearance — stored property so @Observable can track changes
    var appearance: String = UserDefaults.standard.string(forKey: "appearance") ?? "system" {
        didSet { UserDefaults.standard.set(appearance, forKey: "appearance") }
    }
    @ObservationIgnored @AppStorage("reduceAnimations") var reduceAnimations: Bool = false

    // Theme — stored property so @Observable tracks changes and triggers view updates
    var appTheme: String = UserDefaults.standard.string(forKey: "appTheme") ?? "barbie" {
        didSet {
            UserDefaults.standard.set(appTheme, forKey: "appTheme")
            ThemeManager.shared.current = AppThemeId(rawValue: appTheme) ?? .barbie
        }
    }
    @ObservationIgnored @AppStorage("quoteStyle") var quoteStyle: String = "match_theme"  // "match_theme" or theme rawValue

    // Pomodoro
    @ObservationIgnored @AppStorage("pomWorkMinutes") var pomWorkMinutes: Int = 25
    @ObservationIgnored @AppStorage("pomShortBreak") var pomShortBreak: Int = 5
    @ObservationIgnored @AppStorage("pomLongBreak") var pomLongBreak: Int = 15
    @ObservationIgnored @AppStorage("pomSessionsBeforeLong") var pomSessionsBeforeLong: Int = 4
    @ObservationIgnored @AppStorage("pomAutoStartBreak") var pomAutoStartBreak: Bool = true

    // Notifications
    @ObservationIgnored @AppStorage("defaultReminderOffset") var defaultReminderOffset: Int = 0 // minutes before, 0 = at time
    @ObservationIgnored @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true

    // Calendar
    @ObservationIgnored @AppStorage("calendarSyncEnabled") var calendarSyncEnabled: Bool = false
    @ObservationIgnored @AppStorage("remindersSyncEnabled") var remindersSyncEnabled: Bool = false

    // Completion
    @ObservationIgnored @AppStorage("autoCompletionTimestamp") var autoCompletionTimestamp: Bool = true

    // Calendar
    @ObservationIgnored @AppStorage("calendarStartDay") var calendarStartDay: Int = 1  // 1=Sunday, 2=Monday, etc.

    // Detail panel behavior
    @ObservationIgnored @AppStorage("autoOpenDetail") var autoOpenDetail: Bool = true

    // General
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }
    @ObservationIgnored @AppStorage("defaultView") var defaultView: String = "inbox"

    var preferredColorScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
