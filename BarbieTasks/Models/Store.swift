import Foundation
import SwiftUI

@Observable
final class Store {
    // MARK: - Data

    var tasks: [BarbieTask] = []
    var projects: [BarbieProject] = []
    var tags: [BarbieTag] = []
    var pomodoroSessions: [PomodoroSession] = []
    var templates: [TaskTemplate] = []
    var savedFilters: [SavedFilter] = []
    var routines: [Routine] = []

    // MARK: - View State

    var selectedView: ViewSelection = .smartList(.inbox)
    var selectedTaskIds: Set<UUID> = []
    var searchText: String = ""
    var sortBy: SortOption = .manual
    var showCompleted: Bool = false
    var viewMode: ViewMode = .list

    enum ViewMode: String, Codable { case list, kanban }

    // MARK: - UI Triggers

    var focusQuickAdd: Bool = false
    var focusSearch: Bool = false
    var showNewProject: Bool = false
    var showNewTag: Bool = false
    var showCommandPalette: Bool = false
    var celebrationQuote: Quote?
    var showConfetti: Bool = false
    private var celebrationQueue: [(quote: Quote, confetti: Bool)] = []
    private var completionStreak: Int = 0
    var toastMessage: String?
    var showTemplateManager: Bool = false
    var saveAsTemplateTaskId: UUID?
    var showNewFilter: Bool = false
    var editingFilter: SavedFilter?

    // MARK: - Undo / Redo

    private struct UndoEntry {
        let name: String
        let undo: () -> Void
        let redo: () -> Void
    }

    private var undoStack: [UndoEntry] = []
    private var redoStack: [UndoEntry] = []
    private static let maxUndoEntries = 30
    /// Guard flag to prevent undo/redo actions from pushing new entries
    private var isUndoingOrRedoing = false

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    var undoActionName: String? { undoStack.last?.name }
    var redoActionName: String? { redoStack.last?.name }

    private func registerUndo(name: String, undo: @escaping () -> Void, redo: @escaping () -> Void) {
        guard !isUndoingOrRedoing else { return }
        undoStack.append(UndoEntry(name: name, undo: undo, redo: redo))
        if undoStack.count > Self.maxUndoEntries {
            undoStack.removeFirst(undoStack.count - Self.maxUndoEntries)
        }
        redoStack.removeAll()
    }

    // Legacy toast-based undo actions (kept for toast dismiss compatibility)
    private var toastUndoActions: [() -> Void] = []

    // MARK: - View Task Cache

    private var cachedViewTasks: [BarbieTask]?
    private var cachedViewKey: String?

    private func invalidateCache() {
        cachedViewTasks = nil
        cachedViewKey = nil
    }

    // MARK: - Pomodoro

    var pomodoroPhase: PomodoroPhase = .idle
    var pomodoroTaskId: UUID?
    var pomodoroSecondsRemaining: Int = 0
    var pomodoroSessionCount: Int = 0
    private var pomodoroTimer: Timer?

    // MARK: - Convenience

    var selectedTaskId: UUID? {
        get { selectedTaskIds.first }
        set {
            selectedTaskIds = newValue.map { [$0] } ?? []
        }
    }

    var selectedTask: BarbieTask? {
        guard let id = selectedTaskId else { return nil }
        return tasks.first { $0.id == id }
    }

    func selectAll() {
        selectedTaskIds = Set(currentViewTasks.map(\.id))
    }

    func selectNextTask() {
        let tasks = currentViewTasks
        guard !tasks.isEmpty else { return }
        if let currentId = selectedTaskId,
           let currentIndex = tasks.firstIndex(where: { $0.id == currentId }) {
            let nextIndex = min(currentIndex + 1, tasks.count - 1)
            selectedTaskId = tasks[nextIndex].id
        } else {
            selectedTaskId = tasks.first?.id
        }
    }

    func selectPreviousTask() {
        let tasks = currentViewTasks
        guard !tasks.isEmpty else { return }
        if let currentId = selectedTaskId,
           let currentIndex = tasks.firstIndex(where: { $0.id == currentId }) {
            let prevIndex = max(currentIndex - 1, 0)
            selectedTaskId = tasks[prevIndex].id
        } else {
            selectedTaskId = tasks.last?.id
        }
    }

    // MARK: - Selection Cleanup

    private func cleanupSelectedTask() {
        if let id = selectedTaskId, !activeTasks.contains(where: { $0.id == id }) {
            selectedTaskId = nil
        }
    }

    // MARK: - Persistence

    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("BarbieTasks", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("data.json")
    }

    private struct Persisted: Codable {
        var tasks: [BarbieTask]
        var projects: [BarbieProject]
        var tags: [BarbieTag]
        var pomodoroSessions: [PomodoroSession]
        var templates: [TaskTemplate] = []  // default for backward compat
        var savedFilters: [SavedFilter] = []  // default for backward compat
        var routines: [Routine] = []  // default for backward compat
        var selectedView: ViewSelection
        var sortBy: SortOption
        var showCompleted: Bool
    }

    func save() {
        invalidateCache()
        let data = Persisted(
            tasks: tasks, projects: projects, tags: tags,
            pomodoroSessions: pomodoroSessions,
            templates: templates,
            savedFilters: savedFilters,
            routines: routines,
            selectedView: selectedView, sortBy: sortBy,
            showCompleted: showCompleted
        )
        do {
            let json = try JSONEncoder().encode(data)
            try json.write(to: Self.fileURL, options: .atomic)
        } catch {
            print("Save failed: \(error)")
        }
    }

    static func load() -> Store {
        let store = Store()
        guard let json = try? Data(contentsOf: fileURL),
              let data = try? JSONDecoder().decode(Persisted.self, from: json)
        else { return store }
        store.tasks = data.tasks
        store.projects = data.projects
        store.tags = data.tags
        store.pomodoroSessions = data.pomodoroSessions
        store.templates = data.templates
        store.savedFilters = data.savedFilters
        store.routines = data.routines
        store.selectedView = data.selectedView
        store.sortBy = data.sortBy
        store.showCompleted = data.showCompleted
        return store
    }

    // MARK: - Filtered Tasks

    var activeTasks: [BarbieTask] { tasks.filter { !$0.isTrashed } }
    var incompleteTasks: [BarbieTask] { activeTasks.filter { !$0.isDone } }

    var currentViewTasks: [BarbieTask] {
        let key = "\(selectedView.hashValue)-\(searchText)-\(sortBy)-\(showCompleted)-\(viewMode)-\(tasks.hashValue)"
        if let cached = cachedViewTasks, cachedViewKey == key {
            return cached
        }

        var result: [BarbieTask]

        switch selectedView {
        case .smartList(let list):
            switch list {
            case .inbox:
                result = activeTasks.filter { $0.projectId == nil }
            case .today:
                result = activeTasks.filter { !$0.isDone && ($0.isDueToday || $0.isOverdue) }
            case .upcoming:
                result = incompleteTasks.filter { $0.dueDate != nil }
            case .calendar:
                result = activeTasks // calendar view handles its own display
            case .anytime:
                result = activeTasks
            case .logbook:
                result = activeTasks.filter { $0.isDone }
            case .trash:
                result = tasks.filter { $0.isTrashed }
            }
        case .project(let pid):
            result = activeTasks.filter { $0.projectId == pid }
        case .tag(let tid):
            result = activeTasks.filter { $0.tagIds.contains(tid) }
        case .savedFilter(let id):
            guard let filter = savedFilters.first(where: { $0.id == id }) else { result = []; break }
            result = activeTasks.filter { task in
                if !filter.criteria.priorities.isEmpty && !filter.criteria.priorities.contains(task.priority.rawValue) { return false }
                if !filter.criteria.projectIds.isEmpty && !filter.criteria.projectIds.contains(task.projectId ?? UUID()) { return false }
                if !filter.criteria.tagIds.isEmpty && filter.criteria.tagIds.isDisjoint(with: Set(task.tagIds)) { return false }
                if let hasDate = filter.criteria.hasDueDate { if (task.dueDate != nil) != hasDate { return false } }
                if let overdue = filter.criteria.isOverdue { if task.isOverdue != overdue { return false } }
                if let range = filter.criteria.dueDateRange {
                    let cal = Calendar.current
                    switch range {
                    case .today:
                        guard let due = task.dueDate, cal.isDateInToday(due) else { return false }
                    case .thisWeek:
                        guard let due = task.dueDate, cal.isDate(due, equalTo: Date(), toGranularity: .weekOfYear) else { return false }
                    case .thisMonth:
                        guard let due = task.dueDate, cal.isDate(due, equalTo: Date(), toGranularity: .month) else { return false }
                    case .noDate:
                        if task.dueDate != nil { return false }
                    }
                }
                return true
            }
        case .stats:
            result = []
        }

        // Hide completed unless toggled (kanban always shows done for its Done column)
        if !showCompleted && viewMode != .kanban {
            switch selectedView {
            case .smartList(.logbook), .smartList(.trash), .smartList(.today):
                break
            default:
                result = result.filter { !$0.isDone }
            }
        }

        // Search
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(q)
                || $0.notes.lowercased().contains(q)
                || (project(for: $0)?.title.lowercased().contains(q) ?? false)
                || tagsForTask($0).contains { $0.name.lowercased().contains(q) }
            }
        }

        let final = sorted(result)
        cachedViewTasks = final
        cachedViewKey = key
        return final
    }

    private func sorted(_ tasks: [BarbieTask]) -> [BarbieTask] {
        var arr = tasks
        switch sortBy {
        case .manual:
            arr.sort { $0.sortOrder < $1.sortOrder }
        case .dueDate:
            arr.sort {
                switch ($0.dueDate, $1.dueDate) {
                case (nil, nil): return $0.sortOrder < $1.sortOrder
                case (nil, _): return false
                case (_, nil): return true
                case (let a?, let b?): return a < b
                }
            }
        case .priority:
            arr.sort { $0.priority.rawValue > $1.priority.rawValue }
        case .alphabetical:
            arr.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .newest:
            arr.sort { $0.createdAt > $1.createdAt }
        }
        arr.sort { (!$0.isDone ? 0 : 1) < (!$1.isDone ? 0 : 1) }
        return arr
    }

    // MARK: - Counts

    func count(for view: ViewSelection) -> Int {
        switch view {
        case .smartList(let list):
            switch list {
            case .inbox: return incompleteTasks.filter { $0.projectId == nil }.count
            case .today: return activeTasks.filter { !$0.isDone && ($0.isDueToday || $0.isOverdue) }.count
            case .upcoming: return incompleteTasks.filter { $0.dueDate != nil }.count
            case .calendar: return 0
            case .anytime: return incompleteTasks.count
            case .logbook: return activeTasks.filter { $0.isDone }.count
            case .trash: return tasks.filter { $0.isTrashed }.count
            }
        case .project(let pid):
            return incompleteTasks.filter { $0.projectId == pid }.count
        case .tag(let tid):
            return incompleteTasks.filter { $0.tagIds.contains(tid) }.count
        case .savedFilter(let id):
            guard let filter = savedFilters.first(where: { $0.id == id }) else { return 0 }
            return incompleteTasks.filter { task in
                if !filter.criteria.priorities.isEmpty && !filter.criteria.priorities.contains(task.priority.rawValue) { return false }
                if !filter.criteria.projectIds.isEmpty && !filter.criteria.projectIds.contains(task.projectId ?? UUID()) { return false }
                if !filter.criteria.tagIds.isEmpty && filter.criteria.tagIds.isDisjoint(with: Set(task.tagIds)) { return false }
                if let hasDate = filter.criteria.hasDueDate { if (task.dueDate != nil) != hasDate { return false } }
                if let overdue = filter.criteria.isOverdue { if task.isOverdue != overdue { return false } }
                if let range = filter.criteria.dueDateRange {
                    let cal = Calendar.current
                    switch range {
                    case .today:
                        guard let due = task.dueDate, cal.isDateInToday(due) else { return false }
                    case .thisWeek:
                        guard let due = task.dueDate, cal.isDate(due, equalTo: Date(), toGranularity: .weekOfYear) else { return false }
                    case .thisMonth:
                        guard let due = task.dueDate, cal.isDate(due, equalTo: Date(), toGranularity: .month) else { return false }
                    case .noDate:
                        if task.dueDate != nil { return false }
                    }
                }
                return true
            }.count
        case .stats:
            return 0
        }
    }

    var completedToday: Int {
        tasks.filter { $0.isDone && $0.doneAt != nil && Calendar.current.isDateInToday($0.doneAt!) }.count
    }

    var overdueCount: Int {
        activeTasks.filter { $0.isOverdue }.count
    }

    var bestStreak: Int {
        let cal = Calendar.current
        var best = 0
        var current = 0
        // Check last 365 days
        for offset in (0..<365).reversed() {
            let day = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: Date()))!
            let end = cal.date(byAdding: .day, value: 1, to: day)!
            let count = tasks.filter {
                guard let d = $0.doneAt else { return false }
                return d >= day && d < end
            }.count
            if count > 0 {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }

    var completionRate: Double {
        let total = activeTasks.count
        guard total > 0 else { return 0 }
        return Double(activeTasks.filter(\.isDone).count) / Double(total)
    }

    // MARK: - Sorted Collections

    var sortedProjects: [BarbieProject] {
        projects.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    var sortedTags: [BarbieTag] {
        tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - Helpers

    func project(for task: BarbieTask) -> BarbieProject? {
        guard let pid = task.projectId else { return nil }
        return projects.first { $0.id == pid }
    }

    func tagsForTask(_ task: BarbieTask) -> [BarbieTag] {
        task.tagIds.compactMap { tid in tags.first { $0.id == tid } }
    }

    var currentViewLabel: String {
        switch selectedView {
        case .smartList(let l): return l.label
        case .project(let pid): return projects.first { $0.id == pid }?.title ?? "Project"
        case .tag(let tid): return tags.first { $0.id == tid }?.name ?? "Tag"
        case .savedFilter(let id): return savedFilters.first { $0.id == id }?.name ?? "Filter"
        case .stats: return "Statistics"
        }
    }

    var currentViewIcon: String {
        switch selectedView {
        case .smartList(let l): return l.icon
        case .project: return "folder"
        case .tag: return "tag"
        case .savedFilter: return "line.3.horizontal.decrease.circle"
        case .stats: return "chart.bar"
        }
    }

    var isEditableView: Bool {
        switch selectedView {
        case .smartList(let l): return l.isEditable
        case .project, .tag, .savedFilter: return true
        case .stats: return false
        }
    }

    // MARK: - Task CRUD

    func addTask(title: String) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // Natural language parsing
        let parsed = NaturalDateParser.parse(title)

        var task = BarbieTask(title: parsed.title)
        task.sortOrder = (tasks.map(\.sortOrder).max() ?? 0) + 1
        task.dueDate = parsed.dueDate
        task.priority = BarbieTask.Priority(rawValue: parsed.priority) ?? .none

        // Match project by name
        if let projName = parsed.projectName {
            task.projectId = projects.first { $0.title.lowercased() == projName.lowercased() }?.id
        }

        // Match tags by name
        for tagName in parsed.tagNames {
            if let tag = tags.first(where: { $0.name.lowercased() == tagName.lowercased() }) {
                task.tagIds.append(tag.id)
            }
        }

        // Contextual defaults
        if task.dueDate == nil && task.projectId == nil {
            switch selectedView {
            case .smartList(.today):
                task.dueDate = Calendar.current.startOfDay(for: Date())
            case .project(let pid):
                task.projectId = pid
            case .tag(let tid):
                task.tagIds = [tid]
            default:
                break
            }
        }

        if task.projectId == nil {
            if case .project(let pid) = selectedView { task.projectId = pid }
        }

        withAnimation(.smooth(duration: 0.3)) {
            tasks.append(task)
        }

        // Schedule notification if due date set
        if let due = task.dueDate {
            NotificationService.shared.scheduleReminder(
                taskId: task.id, title: task.title, dueDate: due, offsetMinutes: task.reminderOffset ?? 0
            )
        }

        let addedTaskId = task.id
        let addedTask = task
        registerUndo(name: "Add Task") { [weak self] in
            self?.tasks.removeAll { $0.id == addedTaskId }
            NotificationService.shared.cancelReminder(taskId: addedTaskId)
        } redo: { [weak self] in
            self?.tasks.append(addedTask)
            if let due = addedTask.dueDate {
                NotificationService.shared.scheduleReminder(
                    taskId: addedTask.id, title: addedTask.title, dueDate: due,
                    offsetMinutes: addedTask.reminderOffset ?? 0
                )
            }
        }

        save()
    }

    func toggleTask(_ id: UUID) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        let snapshot = tasks[idx]
        let wasCompleting = !tasks[idx].isDone

        // Before toggling, count other undone tasks to detect "all done" milestone
        let othersUndone = wasCompleting ? currentViewTasks.filter { !$0.isDone && $0.id != id }.count : -1

        tasks[idx].isDone.toggle()
        tasks[idx].doneAt = tasks[idx].isDone ? Date() : nil
        tasks[idx].updatedAt = Date()

        // Track any recurrence task spawned so undo can remove it
        var spawnedTaskId: UUID?

        if tasks[idx].isDone {
            completionStreak += 1

            // Every completion gets a quote, streaks get confetti
            if othersUndone == 0 {
                triggerCelebration(message: "Every. Single. Task. DONE. You absolute legend.", withConfetti: true)
            } else if completionStreak.isMultiple(of: 3) {
                let streakMessages = [
                    "HAT TRICK! Three in a row, you're on FIRE!",
                    "Triple threat energy! Keep that streak going!",
                    "Three down, unstoppable vibes only!",
                    "Streak mode: ACTIVATED. You're slaying!",
                ]
                triggerCelebration(message: streakMessages.randomElement()!, withConfetti: true)
            } else {
                triggerCelebration()
            }

            NotificationService.shared.cancelReminder(taskId: id)

            // Handle recurrence
            if let rule = tasks[idx].recurrence, let due = tasks[idx].dueDate {
                let nextDate = rule.nextDate(after: due)
                if rule.endDate == nil || nextDate <= rule.endDate! {
                    var newTask = tasks[idx]
                    newTask.id = UUID()
                    newTask.isDone = false
                    newTask.doneAt = nil
                    newTask.dueDate = nextDate
                    newTask.createdAt = Date()
                    newTask.updatedAt = Date()
                    newTask.pomodoroCount = 0
                    newTask.subtasks = newTask.subtasks.map { var s = $0; s.isDone = false; return s }
                    tasks.append(newTask)
                    spawnedTaskId = newTask.id
                }
            }

            // Sync completion to Reminders
            if let remId = tasks[idx].reminderId {
                RemindersService.shared.completeReminder(identifier: remId, completed: true)
            }
        }

        // Remove from selection when completing (task may disappear from view)
        if wasCompleting {
            selectedTaskIds.remove(id)
        }

        let actionName = wasCompleting ? "Complete Task" : "Uncomplete Task"
        let updatedTask = tasks[idx]
        registerUndo(name: actionName) { [weak self] in
            guard let self, let i = self.tasks.firstIndex(where: { $0.id == id }) else { return }
            self.tasks[i] = snapshot
            // Remove spawned recurrence task if any
            if let sid = spawnedTaskId {
                self.tasks.removeAll { $0.id == sid }
            }
            // Restore reminder if was uncompleted
            if let due = snapshot.dueDate, !snapshot.isDone {
                NotificationService.shared.scheduleReminder(
                    taskId: id, title: snapshot.title, dueDate: due,
                    offsetMinutes: snapshot.reminderOffset ?? 0
                )
            }
        } redo: { [weak self] in
            guard let self, let i = self.tasks.firstIndex(where: { $0.id == id }) else { return }
            self.tasks[i] = updatedTask
            if wasCompleting {
                NotificationService.shared.cancelReminder(taskId: id)
            }
        }

        save()
    }

    func update(_ id: UUID, _ mutation: (inout BarbieTask) -> Void) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        let snapshot = tasks[idx]
        mutation(&tasks[idx])
        tasks[idx].updatedAt = Date()

        // Reschedule notification if due changed
        if let due = tasks[idx].dueDate, !tasks[idx].isDone {
            NotificationService.shared.scheduleReminder(
                taskId: id, title: tasks[idx].title, dueDate: due,
                offsetMinutes: tasks[idx].reminderOffset ?? 0
            )
        } else {
            NotificationService.shared.cancelReminder(taskId: id)
        }

        let updatedTask = tasks[idx]
        registerUndo(name: "Edit Task") { [weak self] in
            guard let self, let i = self.tasks.firstIndex(where: { $0.id == id }) else { return }
            self.tasks[i] = snapshot
            // Restore notification state
            if let due = snapshot.dueDate, !snapshot.isDone {
                NotificationService.shared.scheduleReminder(
                    taskId: id, title: snapshot.title, dueDate: due,
                    offsetMinutes: snapshot.reminderOffset ?? 0
                )
            } else {
                NotificationService.shared.cancelReminder(taskId: id)
            }
        } redo: { [weak self] in
            guard let self, let i = self.tasks.firstIndex(where: { $0.id == id }) else { return }
            self.tasks[i] = updatedTask
            if let due = updatedTask.dueDate, !updatedTask.isDone {
                NotificationService.shared.scheduleReminder(
                    taskId: id, title: updatedTask.title, dueDate: due,
                    offsetMinutes: updatedTask.reminderOffset ?? 0
                )
            } else {
                NotificationService.shared.cancelReminder(taskId: id)
            }
        }

        save()
    }

    func trashTask(_ id: UUID) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        let snapshot = tasks[idx]
        let wasSelected = selectedTaskId == id
        tasks[idx].isTrashed = true
        tasks[idx].trashedAt = Date()
        tasks[idx].updatedAt = Date()
        selectedTaskIds.remove(id)
        NotificationService.shared.cancelReminder(taskId: id)

        // Auto-select next task if the trashed task was selected
        if wasSelected {
            let viewTasks = currentViewTasks
            selectedTaskId = viewTasks.first?.id
        }
        cleanupSelectedTask()

        registerUndo(name: "Trash Task") { [weak self] in
            guard let self, let i = self.tasks.firstIndex(where: { $0.id == id }) else { return }
            self.tasks[i] = snapshot
            if let due = snapshot.dueDate, !snapshot.isDone {
                NotificationService.shared.scheduleReminder(
                    taskId: id, title: snapshot.title, dueDate: due,
                    offsetMinutes: snapshot.reminderOffset ?? 0
                )
            }
        } redo: { [weak self] in
            guard let self, let i = self.tasks.firstIndex(where: { $0.id == id }) else { return }
            self.tasks[i].isTrashed = true
            self.tasks[i].trashedAt = Date()
            self.tasks[i].updatedAt = Date()
            NotificationService.shared.cancelReminder(taskId: id)
        }

        save()

        showToast("Task moved to trash") {
            if let i = self.tasks.firstIndex(where: { $0.id == id }) {
                self.tasks[i] = snapshot
                self.save()
            }
        }
    }

    func permanentlyDelete(_ id: UUID) {
        let snapshot = tasks.first { $0.id == id }
        tasks.removeAll { $0.id == id }
        selectedTaskIds.remove(id)
        cleanupSelectedTask()
        save()

        if let snap = snapshot {
            showToast("Deleted permanently") {
                self.tasks.append(snap)
                self.save()
            }
        }
    }

    func restoreTask(_ id: UUID) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        let snapshot = tasks[idx]
        tasks[idx].isTrashed = false
        tasks[idx].trashedAt = nil
        tasks[idx].updatedAt = Date()

        registerUndo(name: "Restore Task") { [weak self] in
            guard let self, let i = self.tasks.firstIndex(where: { $0.id == id }) else { return }
            self.tasks[i] = snapshot
        } redo: { [weak self] in
            guard let self, let i = self.tasks.firstIndex(where: { $0.id == id }) else { return }
            self.tasks[i].isTrashed = false
            self.tasks[i].trashedAt = nil
            self.tasks[i].updatedAt = Date()
        }

        save()
    }

    func emptyTrash() {
        tasks.removeAll { $0.isTrashed }
        save()
    }

    // MARK: - Duplicate

    func duplicateTask(_ id: UUID) {
        guard let original = tasks.first(where: { $0.id == id }) else { return }
        var copy = original
        copy.id = UUID()
        copy.title = original.title + " (copy)"
        copy.isDone = false
        copy.doneAt = nil
        copy.isInProgress = false
        copy.createdAt = Date()
        copy.updatedAt = Date()
        copy.calendarEventId = nil
        // Reset subtask completion
        copy.subtasks = original.subtasks.map { var s = $0; s.id = UUID(); s.isDone = false; return s }
        tasks.insert(copy, at: (tasks.firstIndex(where: { $0.id == id }) ?? 0) + 1)
        save()
        showToast("Task duplicated")
    }

    // MARK: - Bulk Actions

    func bulkComplete() {
        // Snapshot affected tasks
        let affectedIds = selectedTaskIds
        var snapshots: [UUID: BarbieTask] = [:]
        for id in affectedIds {
            if let idx = tasks.firstIndex(where: { $0.id == id }), !tasks[idx].isDone {
                snapshots[id] = tasks[idx]
                tasks[idx].isDone = true
                tasks[idx].doneAt = Date()
                tasks[idx].updatedAt = Date()
            }
        }

        let prevSelection = affectedIds
        selectedTaskIds = []

        if !snapshots.isEmpty {
            registerUndo(name: "Complete \(snapshots.count) Tasks") { [weak self] in
                guard let self else { return }
                for (id, snap) in snapshots {
                    if let i = self.tasks.firstIndex(where: { $0.id == id }) {
                        self.tasks[i] = snap
                    }
                }
                self.selectedTaskIds = prevSelection
            } redo: { [weak self] in
                guard let self else { return }
                for id in snapshots.keys {
                    if let i = self.tasks.firstIndex(where: { $0.id == id }) {
                        self.tasks[i].isDone = true
                        self.tasks[i].doneAt = Date()
                        self.tasks[i].updatedAt = Date()
                    }
                }
                self.selectedTaskIds = []
            }
        }

        triggerCelebration()
        save()
    }

    func bulkTrash() {
        let affectedIds = selectedTaskIds
        var snapshots: [UUID: BarbieTask] = [:]
        for id in affectedIds {
            if let idx = tasks.firstIndex(where: { $0.id == id }) {
                snapshots[id] = tasks[idx]
                tasks[idx].isTrashed = true
                tasks[idx].trashedAt = Date()
            }
        }

        let prevSelection = affectedIds
        selectedTaskIds = []

        if !snapshots.isEmpty {
            registerUndo(name: "Trash \(snapshots.count) Tasks") { [weak self] in
                guard let self else { return }
                for (id, snap) in snapshots {
                    if let i = self.tasks.firstIndex(where: { $0.id == id }) {
                        self.tasks[i] = snap
                    }
                }
                self.selectedTaskIds = prevSelection
            } redo: { [weak self] in
                guard let self else { return }
                for id in snapshots.keys {
                    if let i = self.tasks.firstIndex(where: { $0.id == id }) {
                        self.tasks[i].isTrashed = true
                        self.tasks[i].trashedAt = Date()
                    }
                }
                self.selectedTaskIds = []
            }
        }

        save()
    }

    func bulkSetPriority(_ p: BarbieTask.Priority) {
        let affectedIds = selectedTaskIds
        var oldPriorities: [UUID: BarbieTask.Priority] = [:]
        for id in affectedIds {
            if let idx = tasks.firstIndex(where: { $0.id == id }) {
                oldPriorities[id] = tasks[idx].priority
                tasks[idx].priority = p
                tasks[idx].updatedAt = Date()
            }
        }

        if !oldPriorities.isEmpty {
            let newPriority = p
            registerUndo(name: "Set Priority") { [weak self] in
                guard let self else { return }
                for (id, oldP) in oldPriorities {
                    if let i = self.tasks.firstIndex(where: { $0.id == id }) {
                        self.tasks[i].priority = oldP
                        self.tasks[i].updatedAt = Date()
                    }
                }
            } redo: { [weak self] in
                guard let self else { return }
                for id in oldPriorities.keys {
                    if let i = self.tasks.firstIndex(where: { $0.id == id }) {
                        self.tasks[i].priority = newPriority
                        self.tasks[i].updatedAt = Date()
                    }
                }
            }
        }

        save()
    }

    func bulkMoveToProject(_ pid: UUID?) {
        let affectedIds = selectedTaskIds
        var oldProjectIds: [UUID: UUID?] = [:]
        for id in affectedIds {
            if let idx = tasks.firstIndex(where: { $0.id == id }) {
                oldProjectIds[id] = tasks[idx].projectId
                tasks[idx].projectId = pid
                tasks[idx].updatedAt = Date()
            }
        }

        if !oldProjectIds.isEmpty {
            let newPid = pid
            registerUndo(name: "Move to Project") { [weak self] in
                guard let self else { return }
                for (id, oldPid) in oldProjectIds {
                    if let i = self.tasks.firstIndex(where: { $0.id == id }) {
                        self.tasks[i].projectId = oldPid
                        self.tasks[i].updatedAt = Date()
                    }
                }
            } redo: { [weak self] in
                guard let self else { return }
                for id in oldProjectIds.keys {
                    if let i = self.tasks.firstIndex(where: { $0.id == id }) {
                        self.tasks[i].projectId = newPid
                        self.tasks[i].updatedAt = Date()
                    }
                }
            }
        }

        save()
    }

    // MARK: - Subtask CRUD

    func addSubtask(to taskId: UUID, text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        update(taskId) { task in
            task.subtasks.append(BarbieTask.Subtask(text: text.trimmingCharacters(in: .whitespaces)))
        }
    }

    func toggleSubtask(taskId: UUID, subtaskId: UUID) {
        update(taskId) { task in
            if let idx = task.subtasks.firstIndex(where: { $0.id == subtaskId }) {
                task.subtasks[idx].isDone.toggle()
            }
        }
    }

    func deleteSubtask(taskId: UUID, subtaskId: UUID) {
        update(taskId) { task in
            task.subtasks.removeAll { $0.id == subtaskId }
        }
    }

    // MARK: - Project CRUD

    func addProject(title: String, colorHex: String) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let p = BarbieProject(
            title: title.trimmingCharacters(in: .whitespaces),
            colorHex: colorHex,
            sortOrder: (projects.map(\.sortOrder).max() ?? 0) + 1
        )
        projects.append(p)
        selectedView = .project(p.id)
        save()
    }

    func deleteProject(_ id: UUID) {
        // Snapshot project and affected tasks
        let deletedProject = projects.first { $0.id == id }
        var affectedTaskSnapshots: [UUID: UUID?] = [:] // taskId -> old projectId
        for i in tasks.indices where tasks[i].projectId == id {
            affectedTaskSnapshots[tasks[i].id] = tasks[i].projectId
            tasks[i].projectId = nil
        }

        let projectIndex = projects.firstIndex(where: { $0.id == id })
        projects.removeAll { $0.id == id }

        let previousView = selectedView
        if case .project(let pid) = selectedView, pid == id {
            selectedView = .smartList(.inbox)
        }

        if let proj = deletedProject {
            let savedProjIndex = projectIndex ?? projects.count
            let viewAfterDelete = selectedView
            registerUndo(name: "Delete Project") { [weak self] in
                guard let self else { return }
                let insertAt = min(savedProjIndex, self.projects.count)
                self.projects.insert(proj, at: insertAt)
                for (taskId, oldPid) in affectedTaskSnapshots {
                    if let i = self.tasks.firstIndex(where: { $0.id == taskId }) {
                        self.tasks[i].projectId = oldPid
                    }
                }
                self.selectedView = previousView
            } redo: { [weak self] in
                guard let self else { return }
                for taskId in affectedTaskSnapshots.keys {
                    if let i = self.tasks.firstIndex(where: { $0.id == taskId }) {
                        self.tasks[i].projectId = nil
                    }
                }
                self.projects.removeAll { $0.id == id }
                self.selectedView = viewAfterDelete
            }
        }

        save()
    }

    func renameProject(_ id: UUID, to name: String) {
        guard let idx = projects.firstIndex(where: { $0.id == id }) else { return }
        projects[idx].title = name
        save()
    }

    // MARK: - Tag CRUD

    func addTag(name: String, colorHex: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let t = BarbieTag(name: name.trimmingCharacters(in: .whitespaces), colorHex: colorHex)
        tags.append(t)
        save()
    }

    func deleteTag(_ id: UUID) {
        // Snapshot tag and which tasks had it
        let deletedTag = tags.first { $0.id == id }
        var tasksWithTag: [UUID] = [] // task IDs that had this tag
        for i in tasks.indices {
            if tasks[i].tagIds.contains(id) {
                tasksWithTag.append(tasks[i].id)
            }
            tasks[i].tagIds.removeAll { $0 == id }
        }

        let tagIndex = tags.firstIndex(where: { $0.id == id })
        tags.removeAll { $0.id == id }

        let previousView = selectedView
        if case .tag(let tid) = selectedView, tid == id {
            selectedView = .smartList(.inbox)
        }

        if let tag = deletedTag {
            let savedTagIndex = tagIndex ?? tags.count
            let viewAfterDelete = selectedView
            registerUndo(name: "Delete Tag") { [weak self] in
                guard let self else { return }
                let insertAt = min(savedTagIndex, self.tags.count)
                self.tags.insert(tag, at: insertAt)
                for taskId in tasksWithTag {
                    if let i = self.tasks.firstIndex(where: { $0.id == taskId }) {
                        if !self.tasks[i].tagIds.contains(id) {
                            self.tasks[i].tagIds.append(id)
                        }
                    }
                }
                self.selectedView = previousView
            } redo: { [weak self] in
                guard let self else { return }
                for taskId in tasksWithTag {
                    if let i = self.tasks.firstIndex(where: { $0.id == taskId }) {
                        self.tasks[i].tagIds.removeAll { $0 == id }
                    }
                }
                self.tags.removeAll { $0.id == id }
                self.selectedView = viewAfterDelete
            }
        }

        save()
    }

    // MARK: - Saved Filter CRUD

    func addSavedFilter(_ filter: SavedFilter) {
        savedFilters.append(filter)
        selectedView = .savedFilter(filter.id)
        save()
    }

    func deleteSavedFilter(_ id: UUID) {
        savedFilters.removeAll { $0.id == id }
        if case .savedFilter(let fid) = selectedView, fid == id {
            selectedView = .smartList(.inbox)
        }
        save()
    }

    func updateSavedFilter(_ id: UUID, _ mutation: (inout SavedFilter) -> Void) {
        guard let idx = savedFilters.firstIndex(where: { $0.id == id }) else { return }
        mutation(&savedFilters[idx])
        save()
    }

    // MARK: - Calendar Integration

    func addTaskToCalendar(_ id: UUID) {
        guard let task = tasks.first(where: { $0.id == id }),
              let due = task.dueDate else { return }
        let eventId = CalendarService.shared.createEvent(
            title: task.title, startDate: due, endDate: nil, notes: task.notes
        )
        if let eventId {
            update(id) { $0.calendarEventId = eventId }
        }
    }

    func removeTaskFromCalendar(_ id: UUID) {
        guard let task = tasks.first(where: { $0.id == id }),
              let eventId = task.calendarEventId else { return }
        CalendarService.shared.deleteEvent(identifier: eventId)
        update(id) { $0.calendarEventId = nil }
    }

    // MARK: - Reminders Import

    func importReminders(_ reminders: [ImportedReminder]) {
        for r in reminders {
            // Skip if already imported
            if tasks.contains(where: { $0.reminderId == r.sourceId }) { continue }
            var task = BarbieTask(title: r.title)
            task.notes = r.notes
            task.dueDate = r.dueDate
            task.isDone = r.isCompleted
            task.doneAt = r.isCompleted ? Date() : nil
            task.priority = BarbieTask.Priority(rawValue: r.priority) ?? .none
            task.reminderId = r.sourceId
            task.sortOrder = (tasks.map(\.sortOrder).max() ?? 0) + 1
            tasks.append(task)
        }
        save()
    }

    func exportTaskToReminders(_ id: UUID, list: EKCalendar) {
        guard let task = tasks.first(where: { $0.id == id }) else { return }
        let remId = RemindersService.shared.exportTask(
            title: task.title, notes: task.notes, dueDate: task.dueDate, toList: list
        )
        if let remId {
            update(id) { $0.reminderId = remId }
        }
    }

    // MARK: - Pomodoro

    func startPomodoro(taskId: UUID?, settings: AppSettings) {
        pomodoroTaskId = taskId
        pomodoroPhase = .working
        pomodoroSecondsRemaining = settings.pomWorkMinutes * 60
        startPomodoroTimer(settings: settings)
    }

    func stopPomodoro() {
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        pomodoroPhase = .idle
        pomodoroSecondsRemaining = 0
        pomodoroTaskId = nil
    }

    func skipPomodoroPhase(settings: AppSettings) {
        pomodoroTimer?.invalidate()
        advancePomodoroPhase(settings: settings)
    }

    private func startPomodoroTimer(settings: AppSettings) {
        pomodoroTimer?.invalidate()
        pomodoroTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.pomodoroSecondsRemaining > 0 {
                self.pomodoroSecondsRemaining -= 1
            } else {
                self.pomodoroTimer?.invalidate()
                self.completePomodoroPhase(settings: settings)
            }
        }
    }

    private func completePomodoroPhase(settings: AppSettings) {
        if pomodoroPhase == .working {
            // Record session
            let session = PomodoroSession(
                taskId: pomodoroTaskId,
                startedAt: Date().addingTimeInterval(TimeInterval(-settings.pomWorkMinutes * 60)),
                duration: TimeInterval(settings.pomWorkMinutes * 60),
                type: .work,
                completed: true
            )
            pomodoroSessions.append(session)
            pomodoroSessionCount += 1

            // Increment task pomodoro count
            if let tid = pomodoroTaskId {
                update(tid) { $0.pomodoroCount += 1 }
            }

            // Notify
            let content = UNMutableNotificationContent()
            content.title = "Focus session complete!"
            content.body = "Time for a break \u{2014} you've earned it."
            content.sound = .default
            let req = UNNotificationRequest(identifier: "pom-\(UUID())", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(req)

            save()
        }

        advancePomodoroPhase(settings: settings)
    }

    private func advancePomodoroPhase(settings: AppSettings) {
        switch pomodoroPhase {
        case .working:
            if pomodoroSessionCount % settings.pomSessionsBeforeLong == 0 {
                pomodoroPhase = .longBreak
                pomodoroSecondsRemaining = settings.pomLongBreak * 60
            } else {
                pomodoroPhase = .shortBreak
                pomodoroSecondsRemaining = settings.pomShortBreak * 60
            }
            if settings.pomAutoStartBreak {
                startPomodoroTimer(settings: settings)
            }
        case .shortBreak, .longBreak:
            pomodoroPhase = .working
            pomodoroSecondsRemaining = settings.pomWorkMinutes * 60
            startPomodoroTimer(settings: settings)
        case .idle:
            break
        }
    }

    // MARK: - Statistics

    func completedTasks(in range: ClosedRange<Date>) -> [BarbieTask] {
        tasks.filter {
            guard let d = $0.doneAt else { return false }
            return range.contains(d)
        }
    }

    func completedPerDay(last days: Int) -> [(Date, Int)] {
        let cal = Calendar.current
        return (0..<days).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: Date()))!
            let end = cal.date(byAdding: .day, value: 1, to: day)!
            let count = tasks.filter {
                guard let d = $0.doneAt else { return false }
                return d >= day && d < end
            }.count
            return (day, count)
        }
    }

    var currentStreak: Int {
        let cal = Calendar.current
        var streak = 0
        var day = cal.startOfDay(for: Date())
        while true {
            let end = cal.date(byAdding: .day, value: 1, to: day)!
            let count = tasks.filter {
                guard let d = $0.doneAt else { return false }
                return d >= day && d < end
            }.count
            if count > 0 {
                streak += 1
                day = cal.date(byAdding: .day, value: -1, to: day)!
            } else {
                break
            }
        }
        return streak
    }

    func tasksForDay(_ date: Date) -> [BarbieTask] {
        let cal = Calendar.current
        return activeTasks.filter { task in
            guard let due = task.dueDate else { return false }
            return cal.isDate(due, inSameDayAs: date)
        }
    }

    // MARK: - Celebration

    private func triggerCelebration(message: String? = nil, withConfetti: Bool = false) {
        let q = message.map { Quote(text: $0) } ?? inspirationalQuotes.randomElement()!

        if celebrationQuote != nil {
            // Queue it
            celebrationQueue.append((quote: q, confetti: withConfetti))
            return
        }

        showCelebration(q, confetti: withConfetti)
    }

    private func showCelebration(_ quote: Quote, confetti: Bool) {
        celebrationQuote = quote
        if confetti {
            showConfetti = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            withAnimation(.smooth(duration: 0.5)) { self?.celebrationQuote = nil }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showConfetti = false
                self?.showNextCelebration()
            }
        }
    }

    private func showNextCelebration() {
        guard !celebrationQueue.isEmpty else { return }
        let next = celebrationQueue.removeFirst()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                self?.showCelebration(next.quote, confetti: next.confetti)
            }
        }
    }

    // MARK: - Toast / Undo

    func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if self.toastMessage == message {
                withAnimation { self.toastMessage = nil }
            }
        }
    }

    private func showToast(_ message: String, undo: @escaping () -> Void) {
        toastMessage = message
        toastUndoActions = [undo]
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if self.toastMessage == message {
                withAnimation { self.toastMessage = nil }
                self.toastUndoActions = []
            }
        }
    }

    func performUndo() {
        // If there's a toast with an undo action, use that first (legacy behavior)
        if let action = toastUndoActions.first {
            action()
            toastUndoActions = []
            withAnimation { toastMessage = nil }
            return
        }
        // Otherwise use the undo stack
        guard let entry = undoStack.popLast() else { return }
        isUndoingOrRedoing = true
        entry.undo()
        redoStack.append(entry)
        isUndoingOrRedoing = false
        save()
    }

    func performRedo() {
        guard let entry = redoStack.popLast() else { return }
        isUndoingOrRedoing = true
        entry.redo()
        undoStack.append(entry)
        if undoStack.count > Self.maxUndoEntries {
            undoStack.removeFirst(undoStack.count - Self.maxUndoEntries)
        }
        isUndoingOrRedoing = false
        save()
    }

    func dismissToast() {
        withAnimation { toastMessage = nil }
        toastUndoActions = []
    }

    // MARK: - Kanban

    func kanbanTasks(for status: BarbieTask.Status) -> [BarbieTask] {
        currentViewTasks.filter { $0.status == status }
    }

    func setTaskStatus(_ id: UUID, to status: BarbieTask.Status) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        let snapshot = tasks[idx]
        tasks[idx].status = status

        let newStatus = status
        registerUndo(name: "Change Status") { [weak self] in
            guard let self, let i = self.tasks.firstIndex(where: { $0.id == id }) else { return }
            self.tasks[i] = snapshot
        } redo: { [weak self] in
            guard let self, let i = self.tasks.firstIndex(where: { $0.id == id }) else { return }
            self.tasks[i].status = newStatus
        }

        save()
    }

    // MARK: - Templates

    func addTemplate(_ template: TaskTemplate) {
        templates.append(template)
        save()
    }

    func saveTaskAsTemplate(_ taskId: UUID, name: String) {
        guard let task = tasks.first(where: { $0.id == taskId }) else { return }
        let template = TaskTemplate.from(task: task, name: name)
        templates.append(template)
        save()
    }

    func createFromTemplate(_ templateId: UUID, dueDate: Date? = nil) {
        guard let template = templates.first(where: { $0.id == templateId }) else { return }
        var task = template.instantiate(dueDate: dueDate)
        task.sortOrder = (tasks.map(\.sortOrder).max() ?? 0) + 1

        // Apply current view context
        if task.projectId == nil {
            if case .project(let pid) = selectedView { task.projectId = pid }
        }

        withAnimation(.smooth(duration: 0.3)) {
            tasks.append(task)
        }

        if let due = task.dueDate {
            NotificationService.shared.scheduleReminder(
                taskId: task.id, title: task.title, dueDate: due, offsetMinutes: task.reminderOffset ?? 0
            )
        }

        save()
    }

    func deleteTemplate(_ id: UUID) {
        templates.removeAll { $0.id == id }
        save()
    }

    func updateTemplate(_ id: UUID, _ mutation: (inout TaskTemplate) -> Void) {
        guard let idx = templates.firstIndex(where: { $0.id == id }) else { return }
        mutation(&templates[idx])
        save()
    }

    // MARK: - Routines

    var showRoutineManager: Bool = false

    var todayRoutines: [Routine] {
        routines.filter(\.isForToday)
    }

    func addRoutine(_ routine: Routine) {
        routines.append(routine)
        save()
    }

    func deleteRoutine(_ id: UUID) {
        routines.removeAll { $0.id == id }
        save()
    }

    func updateRoutine(_ id: UUID, _ mutation: (inout Routine) -> Void) {
        guard let idx = routines.firstIndex(where: { $0.id == id }) else { return }
        mutation(&routines[idx])
        save()
    }

    func activateRoutine(_ id: UUID) {
        guard let routine = routines.first(where: { $0.id == id }) else { return }
        let today = Calendar.current.startOfDay(for: Date())
        var maxOrder = tasks.map(\.sortOrder).max() ?? 0

        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            for rt in routine.tasks {
                var task = BarbieTask(title: rt.title)
                task.priority = rt.priority
                task.projectId = rt.projectId
                task.tagIds = rt.tagIds
                task.notes = rt.notes
                task.dueDate = today
                maxOrder += 1
                task.sortOrder = maxOrder
                tasks.append(task)
            }
        }

        save()
        triggerCelebration(message: "\(routine.name) loaded! Time to slay.", withConfetti: false)
    }

    // MARK: - Import / Export

    func exportJSON() -> Data? {
        let data = Persisted(
            tasks: tasks, projects: projects, tags: tags,
            pomodoroSessions: pomodoroSessions,
            templates: templates,
            savedFilters: savedFilters,
            routines: routines,
            selectedView: .smartList(.inbox), sortBy: sortBy,
            showCompleted: showCompleted
        )
        return try? JSONEncoder().encode(data)
    }

    func importJSON(_ data: Data) -> Bool {
        guard let decoded = try? JSONDecoder().decode(Persisted.self, from: data) else { return false }
        tasks = decoded.tasks
        projects = decoded.projects
        tags = decoded.tags
        pomodoroSessions = decoded.pomodoroSessions
        templates = decoded.templates
        savedFilters = decoded.savedFilters
        save()
        return true
    }
}

// EventKit import
import EventKit
import UserNotifications
