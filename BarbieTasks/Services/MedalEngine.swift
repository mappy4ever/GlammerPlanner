import Foundation

/// Evaluates medal conditions and returns newly unlocked medals.
enum MedalEngine {

    /// Check all medal conditions after a task completion.
    /// Returns the list of newly unlocked medal IDs.
    static func evaluate(
        profile: inout PlayerProfile,
        tasks: [BarbieTask],
        projects: [BarbieProject],
        tags: [BarbieTag],
        pomodoroSessions: [PomodoroSession],
        completedTask: BarbieTask?,
        completedToday: Int,
        currentStreak: Int,
        bestStreak: Int
    ) -> [MedalId] {
        var newUnlocks: [MedalId] = []

        func tryUnlock(_ id: MedalId) {
            guard !profile.hasMedal(id) else { return }
            profile.unlock(id)
            newUnlocks.append(id)
        }

        let totalDone = tasks.filter { $0.isDone && !$0.isTrashed }.count

        // -- Streak medals --
        let streak = max(currentStreak, bestStreak)
        if streak >= 3  { tryUnlock(.onFire) }
        if streak >= 7  { tryUnlock(.weekWarrior) }
        if streak >= 14 { tryUnlock(.twoWeekQueen) }
        if streak >= 30 { tryUnlock(.monthlyLegend) }

        // -- Milestone medals --
        if totalDone >= 1   { tryUnlock(.firstSlay) }
        if totalDone >= 10  { tryUnlock(.firstTen) }
        if totalDone >= 25  { tryUnlock(.quarterCentury) }
        if totalDone >= 50  { tryUnlock(.halfCentury) }
        if totalDone >= 100 { tryUnlock(.century) }
        if totalDone >= 500 { tryUnlock(.fiveHundredClub) }

        // -- Daily medals --
        if completedToday >= 5  { tryUnlock(.perfectDay) }
        if completedToday >= 10 { tryUnlock(.productivityQueen) }

        if completedToday >= profile.dailyGoal && profile.dailyGoal > 0 {
            tryUnlock(.dailyGoalSmashed)
        }

        if let task = completedTask {
            let hour = Calendar.current.component(.hour, from: task.doneAt ?? Date())
            if hour < 9  { tryUnlock(.earlyBird) }
            if hour >= 22 { tryUnlock(.nightOwl) }

            // Overdue comeback
            if task.isOverdue || (task.dueDate != nil && task.doneAt != nil) {
                if let due = task.dueDate, let done = task.doneAt {
                    let dueDay = Calendar.current.startOfDay(for: due)
                    let doneDay = Calendar.current.startOfDay(for: done)
                    if doneDay > dueDay {
                        tryUnlock(.comeback)
                    }
                }
            }

            // Subtask slayer
            if task.subtasks.count >= 5 && task.subtasks.allSatisfy(\.isDone) {
                tryUnlock(.subtaskSlayer)
            }

            // Power hour — 5 tasks completed within the last hour
            let oneHourAgo = Date().addingTimeInterval(-3600)
            let recentCompletions = tasks.filter {
                $0.isDone && !$0.isTrashed && ($0.doneAt ?? .distantPast) >= oneHourAgo
            }.count
            if recentCompletions >= 5 { tryUnlock(.powerHour) }
        }

        // -- Focus medals --
        let pomCount = pomodoroSessions.count
        if pomCount >= 1   { tryUnlock(.focusStarter) }
        if pomCount >= 5   { tryUnlock(.deepFocus) }
        if pomCount >= 25  { tryUnlock(.focusMaster) }
        if pomCount >= 100 { tryUnlock(.zenMaster) }

        // -- Planning medals --
        let tasksWithDue = tasks.filter { $0.dueDate != nil && !$0.isTrashed }.count
        if tasksWithDue >= 10 { tryUnlock(.planner) }

        // Week planner — 5+ tasks due next week
        let cal = Calendar.current
        let nextWeekStart = cal.date(byAdding: .weekOfYear, value: 1, to: cal.startOfDay(for: Date()))!
        let nextWeekEnd = cal.date(byAdding: .day, value: 7, to: nextWeekStart)!
        let nextWeekTasks = tasks.filter {
            guard let due = $0.dueDate, !$0.isTrashed else { return false }
            return due >= nextWeekStart && due < nextWeekEnd
        }.count
        if nextWeekTasks >= 5 { tryUnlock(.weekPlanner) }

        if projects.count >= 3 { tryUnlock(.organizer) }
        if tags.count >= 5 { tryUnlock(.tagQueen) }

        return newUnlocks
    }

    /// Backfill medals from existing task history (called on first launch with new system).
    static func backfill(
        profile: inout PlayerProfile,
        tasks: [BarbieTask],
        projects: [BarbieProject],
        tags: [BarbieTag],
        pomodoroSessions: [PomodoroSession],
        currentStreak: Int,
        bestStreak: Int
    ) -> [MedalId] {
        let completedToday = tasks.filter {
            $0.isDone && $0.doneAt != nil && Calendar.current.isDateInToday($0.doneAt!)
        }.count

        return evaluate(
            profile: &profile,
            tasks: tasks,
            projects: projects,
            tags: tags,
            pomodoroSessions: pomodoroSessions,
            completedTask: nil,
            completedToday: completedToday,
            currentStreak: currentStreak,
            bestStreak: bestStreak
        )
    }
}
