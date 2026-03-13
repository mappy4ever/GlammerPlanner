import EventKit
import Foundation

@Observable
final class RemindersService {
    static let shared = RemindersService()

    private let store = EKEventStore()
    var hasAccess = false
    var reminderLists: [EKCalendar] = []

    private init() {}

    // MARK: - Authorization

    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestFullAccessToReminders()
            await MainActor.run { hasAccess = granted }
            if granted { loadLists() }
            return granted
        } catch {
            print("Reminders access error: \(error)")
            return false
        }
    }

    // MARK: - Lists

    func loadLists() {
        reminderLists = store.calendars(for: .reminder)
    }

    // MARK: - Import

    func importReminders(from list: EKCalendar) async -> [ImportedReminder] {
        guard hasAccess else { return [] }
        let predicate = store.predicateForReminders(in: [list])
        do {
            let reminders = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[EKReminder], Error>) in
                store.fetchReminders(matching: predicate) { result in
                    cont.resume(returning: result ?? [])
                }
            }
            return reminders.map { r in
                ImportedReminder(
                    title: r.title ?? "Untitled",
                    notes: r.notes ?? "",
                    dueDate: r.dueDateComponents.flatMap { Calendar.current.date(from: $0) },
                    isCompleted: r.isCompleted,
                    priority: mapPriority(r.priority),
                    sourceId: r.calendarItemIdentifier
                )
            }
        } catch {
            print("Fetch reminders error: \(error)")
            return []
        }
    }

    // MARK: - Export

    func exportTask(title: String, notes: String, dueDate: Date?, toList list: EKCalendar) -> String? {
        guard hasAccess else { return nil }
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = list
        if let due = dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: due
            )
        }
        do {
            try store.save(reminder, commit: true)
            return reminder.calendarItemIdentifier
        } catch {
            print("Export reminder error: \(error)")
            return nil
        }
    }

    func completeReminder(identifier: String, completed: Bool) {
        guard hasAccess else { return }
        let predicate = store.predicateForReminders(in: nil)
        store.fetchReminders(matching: predicate) { [weak self] reminders in
            guard let reminder = reminders?.first(where: { $0.calendarItemIdentifier == identifier }) else { return }
            reminder.isCompleted = completed
            try? self?.store.save(reminder, commit: true)
        }
    }

    // MARK: - Helpers

    private func mapPriority(_ ekPriority: Int) -> Int {
        switch ekPriority {
        case 1...4: return 3  // high
        case 5: return 2      // medium
        case 6...9: return 1  // low
        default: return 0     // none
        }
    }
}

struct ImportedReminder {
    let title: String
    let notes: String
    let dueDate: Date?
    let isCompleted: Bool
    let priority: Int
    let sourceId: String
}
