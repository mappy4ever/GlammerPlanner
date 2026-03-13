import Foundation

struct TaskTemplate: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var title: String
    var notes: String = ""
    var priority: BarbieTask.Priority = .none
    var subtasks: [String] = []
    var tagIds: [UUID] = []
    var projectId: UUID?
    var recurrence: RecurrenceRule?
    var reminderOffset: Int?
    var createdAt: Date = Date()

    /// Create a BarbieTask from this template.
    func instantiate(dueDate: Date? = nil) -> BarbieTask {
        var task = BarbieTask(title: title)
        task.notes = notes
        task.priority = priority
        task.subtasks = subtasks.map { BarbieTask.Subtask(text: $0) }
        task.tagIds = tagIds
        task.projectId = projectId
        task.recurrence = recurrence
        task.reminderOffset = reminderOffset
        task.dueDate = dueDate
        task.templateId = id
        return task
    }

    /// Create a template from an existing task.
    static func from(task: BarbieTask, name: String) -> TaskTemplate {
        TaskTemplate(
            name: name,
            title: task.title,
            notes: task.notes,
            priority: task.priority,
            subtasks: task.subtasks.map(\.text),
            tagIds: task.tagIds,
            projectId: task.projectId,
            recurrence: task.recurrence,
            reminderOffset: task.reminderOffset
        )
    }
}
