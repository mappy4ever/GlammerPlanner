import Foundation
import SwiftUI

// MARK: - Medal Definition

enum MedalId: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    // Streak medals
    case onFire           // 3-day streak
    case weekWarrior      // 7-day streak
    case twoWeekQueen     // 14-day streak
    case monthlyLegend    // 30-day streak

    // Milestone medals
    case firstSlay        // Complete first task ever
    case firstTen         // 10 tasks completed
    case quarterCentury   // 25 tasks completed
    case halfCentury      // 50 tasks completed
    case century          // 100 tasks completed
    case fiveHundredClub  // 500 tasks completed

    // Daily medals
    case earlyBird        // Complete a task before 9 AM
    case nightOwl         // Complete a task after 10 PM
    case powerHour        // Complete 5 tasks in one hour
    case perfectDay       // Complete 5+ tasks in a day
    case productivityQueen // Complete 10+ tasks in a day
    case dailyGoalSmashed // Hit daily goal

    // Focus medals
    case focusStarter     // Complete first pomodoro
    case deepFocus        // 5 pomodoro sessions
    case focusMaster      // 25 pomodoro sessions
    case zenMaster        // 100 pomodoro sessions

    // Planning medals
    case planner          // Set due dates on 10 tasks
    case weekPlanner      // Plan 5+ tasks for next week
    case organizer        // Create 3 projects
    case tagQueen         // Use 5+ different tags

    // Special medals
    case comeback         // Complete a task that was overdue
    case zeroBoss         // Clear all tasks (inbox zero)
    case subtaskSlayer    // Complete a task with 5+ subtasks all done
    case kanbanKing       // Move a task through all 3 kanban stages

    var definition: MedalDefinition {
        switch self {
        // Streaks
        case .onFire:           MedalDefinition(id: self, title: "On Fire", description: "Maintain a 3-day streak", icon: "flame.fill", tier: .bronze, category: .streak)
        case .weekWarrior:      MedalDefinition(id: self, title: "Week Warrior", description: "Maintain a 7-day streak", icon: "flame.fill", tier: .silver, category: .streak)
        case .twoWeekQueen:     MedalDefinition(id: self, title: "Two-Week Titan", description: "Maintain a 14-day streak", icon: "flame.fill", tier: .gold, category: .streak)
        case .monthlyLegend:    MedalDefinition(id: self, title: "Monthly Legend", description: "Maintain a 30-day streak", icon: "flame.fill", tier: .diamond, category: .streak)

        // Milestones
        case .firstSlay:        MedalDefinition(id: self, title: "First Win", description: "Complete your first task", icon: "sparkles", tier: .bronze, category: .milestone)
        case .firstTen:         MedalDefinition(id: self, title: "First Ten", description: "Complete 10 tasks", icon: "star.fill", tier: .bronze, category: .milestone)
        case .quarterCentury:   MedalDefinition(id: self, title: "Quarter Century", description: "Complete 25 tasks", icon: "star.fill", tier: .silver, category: .milestone)
        case .halfCentury:      MedalDefinition(id: self, title: "Half Century", description: "Complete 50 tasks", icon: "crown.fill", tier: .silver, category: .milestone)
        case .century:          MedalDefinition(id: self, title: "Century Legend", description: "Complete 100 tasks", icon: "crown.fill", tier: .gold, category: .milestone)
        case .fiveHundredClub:  MedalDefinition(id: self, title: "500 Club", description: "Complete 500 tasks", icon: "crown.fill", tier: .diamond, category: .milestone)

        // Daily
        case .earlyBird:        MedalDefinition(id: self, title: "Early Bird", description: "Complete a task before 9 AM", icon: "sunrise.fill", tier: .bronze, category: .daily)
        case .nightOwl:         MedalDefinition(id: self, title: "Night Owl", description: "Complete a task after 10 PM", icon: "moon.stars.fill", tier: .bronze, category: .daily)
        case .powerHour:        MedalDefinition(id: self, title: "Power Hour", description: "Complete 5 tasks in one hour", icon: "bolt.fill", tier: .gold, category: .daily)
        case .perfectDay:       MedalDefinition(id: self, title: "Perfect Day", description: "Complete 5+ tasks in a day", icon: "checkmark.seal.fill", tier: .silver, category: .daily)
        case .productivityQueen: MedalDefinition(id: self, title: "Productivity Beast", description: "Complete 10+ tasks in a day", icon: "checkmark.seal.fill", tier: .gold, category: .daily)
        case .dailyGoalSmashed: MedalDefinition(id: self, title: "Goal Smasher", description: "Hit your daily task goal", icon: "target", tier: .silver, category: .daily)

        // Focus
        case .focusStarter:     MedalDefinition(id: self, title: "Focus Starter", description: "Complete your first pomodoro", icon: "timer", tier: .bronze, category: .focus)
        case .deepFocus:        MedalDefinition(id: self, title: "Deep Focus", description: "Complete 5 pomodoro sessions", icon: "timer", tier: .silver, category: .focus)
        case .focusMaster:      MedalDefinition(id: self, title: "Focus Master", description: "Complete 25 pomodoro sessions", icon: "timer", tier: .gold, category: .focus)
        case .zenMaster:        MedalDefinition(id: self, title: "Zen Master", description: "Complete 100 pomodoro sessions", icon: "timer", tier: .diamond, category: .focus)

        // Planning
        case .planner:          MedalDefinition(id: self, title: "Planner", description: "Set due dates on 10 tasks", icon: "calendar", tier: .bronze, category: .planning)
        case .weekPlanner:      MedalDefinition(id: self, title: "Week Planner", description: "Plan 5+ tasks for next week", icon: "calendar.badge.clock", tier: .silver, category: .planning)
        case .organizer:        MedalDefinition(id: self, title: "Organizer", description: "Create 3 projects", icon: "folder.fill", tier: .bronze, category: .planning)
        case .tagQueen:         MedalDefinition(id: self, title: "Tag Master", description: "Use 5+ different tags", icon: "tag.fill", tier: .silver, category: .planning)

        // Special
        case .comeback:         MedalDefinition(id: self, title: "Comeback Champion", description: "Complete an overdue task", icon: "arrow.uturn.up", tier: .silver, category: .special)
        case .zeroBoss:         MedalDefinition(id: self, title: "Zero Boss", description: "Clear all tasks in a view", icon: "tray.fill", tier: .gold, category: .special)
        case .subtaskSlayer:    MedalDefinition(id: self, title: "Subtask Slayer", description: "Complete a task with 5+ subtasks", icon: "checklist", tier: .silver, category: .special)
        case .kanbanKing:       MedalDefinition(id: self, title: "Kanban Pro", description: "Move task through all 3 stages", icon: "rectangle.split.3x1.fill", tier: .gold, category: .special)
        }
    }
}

// MARK: - Medal Tier

enum MedalTier: String, CaseIterable, Comparable {
    case bronze, silver, gold, diamond

    static func < (lhs: MedalTier, rhs: MedalTier) -> Bool {
        let order: [MedalTier] = [.bronze, .silver, .gold, .diamond]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

// Backward-compatible Codable: accepts "pink" from old data, writes "diamond"
extension MedalTier: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        if raw == "pink" {
            self = .diamond
        } else if let value = MedalTier(rawValue: raw) {
            self = value
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown MedalTier: \(raw)")
        }
    }

    var colors: [Color] {
        switch self {
        case .bronze: [Color(hex: "#CD7F32"), Color(hex: "#B87333")]
        case .silver: [Color(hex: "#C0C0C0"), Color(hex: "#A8A9AD")]
        case .gold:   [.gold, Color(hex: "#DAA520")]
        case .diamond: [ThemeManager.shared.palette.primary, ThemeManager.shared.palette.primaryDeep]
        }
    }

    var glowColor: Color {
        switch self {
        case .bronze: Color(hex: "#CD7F32")
        case .silver: Color(hex: "#C0C0C0")
        case .gold:   .gold
        case .diamond: ThemeManager.shared.palette.primary
        }
    }

    var label: String {
        switch self {
        case .bronze: "Bronze"
        case .silver: "Silver"
        case .gold:   "Gold"
        case .diamond: "Diamond"
        }
    }
}

// MARK: - Medal Category

enum MedalCategory: String, Codable, CaseIterable {
    case streak, milestone, daily, focus, planning, special

    var label: String {
        switch self {
        case .streak: "Streaks"
        case .milestone: "Milestones"
        case .daily: "Daily"
        case .focus: "Focus"
        case .planning: "Planning"
        case .special: "Special"
        }
    }

    var icon: String {
        switch self {
        case .streak: "flame.fill"
        case .milestone: "trophy.fill"
        case .daily: "sun.max.fill"
        case .focus: "timer"
        case .planning: "calendar"
        case .special: "sparkles"
        }
    }
}

// MARK: - Medal Definition

struct MedalDefinition {
    let id: MedalId
    let title: String
    let description: String
    let icon: String
    let tier: MedalTier
    let category: MedalCategory
}

// MARK: - Medal Unlock Record

struct MedalUnlock: Codable, Identifiable, Equatable {
    var id: String { medalId.rawValue }
    let medalId: MedalId
    let unlockedAt: Date

    static func == (lhs: MedalUnlock, rhs: MedalUnlock) -> Bool {
        lhs.medalId == rhs.medalId
    }
}

// MARK: - Player Profile (persisted)

struct PlayerProfile: Codable {
    var unlockedMedals: [MedalUnlock] = []
    var dailyGoal: Int = 5  // target tasks per day
    var lifetimeCompleted: Int = 0
    var firstTaskOfDayDone: Bool = false  // reset daily
    var lastFirstTaskDate: String?  // "yyyy-MM-dd" to track daily reset

    func hasMedal(_ id: MedalId) -> Bool {
        unlockedMedals.contains { $0.medalId == id }
    }

    mutating func unlock(_ id: MedalId) {
        guard !hasMedal(id) else { return }
        unlockedMedals.append(MedalUnlock(medalId: id, unlockedAt: Date()))
    }

    var unlockedCount: Int { unlockedMedals.count }
    var totalMedals: Int { MedalId.allCases.count }

    var dailyGoalProgress: Double {
        // This will be calculated externally with completedToday
        0
    }
}
