import UserNotifications
import Foundation

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    func scheduleReminder(taskId: UUID, title: String, dueDate: Date, offsetMinutes: Int = 0) {
        let center = UNUserNotificationCenter.current()

        // Remove existing notification for this task
        center.removePendingNotificationRequests(withIdentifiers: [taskId.uuidString])

        let content = UNMutableNotificationContent()
        content.title = "Slay List"
        content.body = title
        content.sound = .default
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = ["taskId": taskId.uuidString]

        let fireDate = Calendar.current.date(byAdding: .minute, value: -offsetMinutes, to: dueDate) ?? dueDate
        guard fireDate > Date() else { return }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: taskId.uuidString, content: content, trigger: trigger
        )

        center.add(request) { error in
            if let error { print("Schedule notification error: \(error)") }
        }
    }

    func cancelReminder(taskId: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [taskId.uuidString])
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func registerActions() {
        let complete = UNNotificationAction(identifier: "COMPLETE", title: "Complete", options: [])
        let snooze = UNNotificationAction(identifier: "SNOOZE_15", title: "Snooze 15 min", options: [])
        let category = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [complete, snooze],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
