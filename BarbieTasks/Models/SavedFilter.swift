import Foundation
import SwiftUI

struct SavedFilter: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var colorHex: String = "#D4577A"
    var criteria: FilterCriteria
    var createdAt = Date()

    var color: Color { Color(hex: colorHex) }

    struct FilterCriteria: Codable, Hashable {
        var priorities: Set<Int> = []          // empty = any
        var projectIds: Set<UUID> = []         // empty = any
        var tagIds: Set<UUID> = []             // empty = any
        var hasDueDate: Bool? = nil            // nil = don't filter
        var isOverdue: Bool? = nil
        var dueDateRange: DateRange? = nil

        enum DateRange: String, Codable, Hashable, CaseIterable {
            case today, thisWeek, thisMonth, noDate

            var label: String {
                switch self {
                case .today: "Today"
                case .thisWeek: "This Week"
                case .thisMonth: "This Month"
                case .noDate: "No Date"
                }
            }
        }
    }
}
