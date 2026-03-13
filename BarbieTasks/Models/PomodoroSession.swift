import Foundation

struct PomodoroSession: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var taskId: UUID?
    var startedAt: Date
    var duration: TimeInterval  // seconds
    var type: SessionType
    var completed: Bool

    enum SessionType: String, Codable, Hashable {
        case work, shortBreak, longBreak

        var label: String {
            switch self {
            case .work: "Focus"
            case .shortBreak: "Break"
            case .longBreak: "Long Break"
            }
        }
    }
}

enum PomodoroPhase: String, Codable {
    case idle, working, shortBreak, longBreak
}
