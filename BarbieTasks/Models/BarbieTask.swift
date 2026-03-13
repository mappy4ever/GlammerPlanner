import Foundation

struct BarbieTask: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var notes: String = ""
    var isDone: Bool = false
    var doneAt: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var dueDate: Date?
    var projectId: UUID?
    var priority: Priority = .none
    var subtasks: [Subtask] = []
    var sortOrder: Int = 0
    var isTrashed: Bool = false
    var trashedAt: Date?

    // Tags
    var tagIds: [UUID] = []

    // Recurrence
    var recurrence: RecurrenceRule?

    // Apple integration
    var calendarEventId: String?
    var reminderId: String?
    var reminderOffset: Int?       // minutes before due to notify (nil = no notification)

    // Pomodoro
    var pomodoroCount: Int = 0

    // Attachments
    var attachments: [TaskAttachment] = []

    // Kanban status
    var isInProgress: Bool = false

    // Template source
    var templateId: UUID?

    // MARK: - Priority

    enum Priority: Int, Codable, CaseIterable, Identifiable, Hashable {
        case none = 0, low = 1, medium = 2, high = 3

        var id: Int { rawValue }

        var label: String {
            switch self {
            case .none: "None"
            case .low: "Low"
            case .medium: "Medium"
            case .high: "High"
            }
        }

        var symbol: String {
            switch self {
            case .none: "minus"
            case .low: "arrow.down"
            case .medium: "equal"
            case .high: "arrow.up"
            }
        }
    }

    // MARK: - Subtask

    struct Subtask: Identifiable, Codable, Hashable {
        var id: UUID = UUID()
        var text: String
        var isDone: Bool = false
    }

    // MARK: - Computed

    var isOverdue: Bool {
        guard let due = dueDate, !isDone else { return false }
        return Calendar.current.startOfDay(for: due) < Calendar.current.startOfDay(for: Date())
    }

    var isDueToday: Bool {
        guard let due = dueDate else { return false }
        return Calendar.current.isDateInToday(due)
    }

    var isDueTomorrow: Bool {
        guard let due = dueDate else { return false }
        return Calendar.current.isDateInTomorrow(due)
    }

    var isDueThisWeek: Bool {
        guard let due = dueDate else { return false }
        return Calendar.current.isDate(due, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var subtaskProgress: String? {
        guard !subtasks.isEmpty else { return nil }
        let done = subtasks.filter(\.isDone).count
        return "\(done)/\(subtasks.count)"
    }

    var formattedDue: String? {
        guard let due = dueDate else { return nil }
        if isDueToday { return "Today" }
        if isDueTomorrow { return "Tomorrow" }
        if isOverdue {
            let days = Calendar.current.dateComponents([.day], from: due, to: Date()).day ?? 0
            return days == 1 ? "Yesterday" : "\(days)d overdue"
        }
        if isDueThisWeek {
            return due.formatted(.dateTime.weekday(.wide))
        }
        return due.formatted(.dateTime.month(.abbreviated).day())
    }

    var hasExtras: Bool {
        !notes.isEmpty || !subtasks.isEmpty || !attachments.isEmpty || !tagIds.isEmpty
    }

    // MARK: - Kanban

    enum Status: String, Codable, CaseIterable, Identifiable {
        case todo, inProgress, done

        var id: String { rawValue }

        var label: String {
            switch self {
            case .todo: "To Do"
            case .inProgress: "In Progress"
            case .done: "Done"
            }
        }

        var icon: String {
            switch self {
            case .todo: "circle"
            case .inProgress: "arrow.right.circle.fill"
            case .done: "checkmark.circle.fill"
            }
        }
    }

    var status: Status {
        get {
            if isDone { return .done }
            if isInProgress { return .inProgress }
            return .todo
        }
        set {
            switch newValue {
            case .todo:
                isDone = false
                doneAt = nil
                isInProgress = false
            case .inProgress:
                isDone = false
                doneAt = nil
                isInProgress = true
            case .done:
                isDone = true
                doneAt = Date()
                isInProgress = false
            }
            updatedAt = Date()
        }
    }
}
