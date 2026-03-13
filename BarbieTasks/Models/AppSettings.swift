import Foundation
import SwiftUI

@Observable
final class AppSettings {
    // Appearance
    @ObservationIgnored @AppStorage("appearance") var appearance: String = "system"  // "light"/"dark"/"system"
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
    @ObservationIgnored @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @ObservationIgnored @AppStorage("defaultView") var defaultView: String = "inbox"

    var preferredColorScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
