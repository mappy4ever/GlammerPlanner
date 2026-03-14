import Foundation

// MARK: - Smart List

enum SmartList: String, CaseIterable, Identifiable, Codable, Hashable {
    case inbox, today, upcoming, calendar, anytime, logbook, trash

    var id: String { rawValue }

    var label: String {
        switch self {
        case .inbox: "My Slay List"
        case .today: "Today"
        case .upcoming: "Upcoming"
        case .calendar: "Calendar"
        case .anytime: "All Tasks"
        case .logbook: "Slayed Tasks"
        case .trash: "Trash"
        }
    }

    var icon: String {
        switch self {
        case .inbox: "tray"
        case .today: "star"
        case .upcoming: "calendar.badge.clock"
        case .calendar: "calendar"
        case .anytime: "list.bullet"
        case .logbook: "book.closed"
        case .trash: "trash"
        }
    }

    var isEditable: Bool {
        self != .logbook && self != .trash && self != .calendar
    }

    static var primary: [SmartList] { [.inbox, .today, .upcoming, .calendar, .anytime] }
    static var secondary: [SmartList] { [.logbook, .trash] }
}

// MARK: - View Selection

enum ViewSelection: Hashable, Codable {
    case smartList(SmartList)
    case project(UUID)
    case tag(UUID)
    case savedFilter(UUID)
    case stats
}

// MARK: - Sort

enum SortOption: String, CaseIterable, Identifiable, Codable {
    case manual, dueDate, priority, alphabetical, newest

    var id: String { rawValue }

    var label: String {
        switch self {
        case .manual: "Manual"
        case .dueDate: "Due Date"
        case .priority: "Priority"
        case .alphabetical: "A\u{2013}Z"
        case .newest: "Newest"
        }
    }
}

// MARK: - Quote

struct Quote: Identifiable, Equatable {
    let id = UUID()
    let text: String

    static func == (lhs: Quote, rhs: Quote) -> Bool {
        lhs.id == rhs.id
    }
}

var inspirationalQuotes: [String] {
    let style = UserDefaults.standard.string(forKey: "quoteStyle") ?? "match_theme"
    if style != "match_theme", let theme = AppThemeId(rawValue: style) {
        return quotesForTheme(theme)
    }
    return quotesForTheme(ThemeManager.shared.current)
}
