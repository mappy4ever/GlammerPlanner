import Foundation

struct RecurrenceRule: Codable, Hashable {
    var frequency: Frequency
    var interval: Int = 1
    var daysOfWeek: [Int]?   // 1=Sun..7=Sat (for weekly)
    var endDate: Date?

    enum Frequency: String, Codable, CaseIterable, Identifiable, Hashable {
        case daily, weekly, monthly, yearly

        var id: String { rawValue }

        var label: String {
            switch self {
            case .daily: "Daily"
            case .weekly: "Weekly"
            case .monthly: "Monthly"
            case .yearly: "Yearly"
            }
        }
    }

    var summary: String {
        let base: String
        switch frequency {
        case .daily:   base = interval == 1 ? "Every day" : "Every \(interval) days"
        case .weekly:  base = interval == 1 ? "Every week" : "Every \(interval) weeks"
        case .monthly: base = interval == 1 ? "Every month" : "Every \(interval) months"
        case .yearly:  base = interval == 1 ? "Every year" : "Every \(interval) years"
        }
        return base
    }

    func nextDate(after date: Date) -> Date {
        let cal = Calendar.current
        switch frequency {
        case .daily:
            return cal.date(byAdding: .day, value: interval, to: date)!
        case .weekly:
            return cal.date(byAdding: .weekOfYear, value: interval, to: date)!
        case .monthly:
            return cal.date(byAdding: .month, value: interval, to: date)!
        case .yearly:
            return cal.date(byAdding: .year, value: interval, to: date)!
        }
    }
}
