import Foundation

struct Routine: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var tasks: [RoutineTask] = []
    var days: Set<Int> = [] // 1=Sunday, 2=Monday, ... 7=Saturday (Calendar.component .weekday)
    var createdAt: Date = Date()

    /// Whether this routine is scheduled for today
    var isForToday: Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return days.contains(weekday)
    }

    /// Human-readable days summary
    var daysSummary: String {
        if days.count == 7 { return "Every day" }
        if days.isEmpty { return "No days set" }
        let names = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sorted = days.sorted()
        // Check for weekdays
        if sorted == [2, 3, 4, 5, 6] { return "Weekdays" }
        if sorted == [1, 7] { return "Weekends" }
        return sorted.map { names[$0] }.joined(separator: ", ")
    }
}

struct RoutineTask: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var priority: BarbieTask.Priority = .none
    var projectId: UUID?
    var tagIds: [UUID] = []
    var notes: String = ""
}
