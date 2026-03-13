import Foundation
import SwiftUI

@Observable
final class AppSettings {
    // Appearance — stored property so @Observable can track changes
    var appearance: String = UserDefaults.standard.string(forKey: "appearance") ?? "system" {
        didSet { UserDefaults.standard.set(appearance, forKey: "appearance") }
    }
    @ObservationIgnored @AppStorage("reduceAnimations") var reduceAnimations: Bool = false

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
