import Foundation

/// Parses natural language from quick-add input.
/// "Buy milk tomorrow 3pm !!" → title="Buy milk", dueDate=tomorrow 3pm, priority=medium
/// "Meeting next friday #Work @urgent" → title="Meeting", dueDate=next friday, project="Work", tags=["urgent"]
struct NaturalDateParser {

    struct Result {
        var title: String
        var dueDate: Date?
        var priority: Int = 0
        var projectName: String?
        var tagNames: [String] = []
    }

    static func parse(_ input: String) -> Result {
        var text = input.trimmingCharacters(in: .whitespaces)
        var result = Result(title: text)

        // Extract priority markers (! = low, !! = med, !!! = high)
        if text.hasSuffix("!!!") {
            result.priority = 3
            text = String(text.dropLast(3)).trimmingCharacters(in: .whitespaces)
        } else if text.hasSuffix("!!") {
            result.priority = 2
            text = String(text.dropLast(2)).trimmingCharacters(in: .whitespaces)
        } else if text.hasSuffix("!") {
            result.priority = 1
            text = String(text.dropLast(1)).trimmingCharacters(in: .whitespaces)
        }

        // Extract #project
        if let range = text.range(of: #"#(\w+)"#, options: .regularExpression) {
            let match = String(text[range]).dropFirst() // remove #
            result.projectName = String(match)
            text.removeSubrange(range)
            text = text.trimmingCharacters(in: .whitespaces)
        }

        // Extract @tags
        while let range = text.range(of: #"@(\w+)"#, options: .regularExpression) {
            let match = String(text[range]).dropFirst()
            result.tagNames.append(String(match))
            text.removeSubrange(range)
            text = text.trimmingCharacters(in: .whitespaces)
        }

        // Try keyword date patterns first
        let lowered = text.lowercased()
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        let dateKeywords: [(String, Date)] = [
            ("today", today),
            ("tomorrow", cal.date(byAdding: .day, value: 1, to: today)!),
            ("next week", cal.date(byAdding: .weekOfYear, value: 1, to: today)!),
            ("next month", cal.date(byAdding: .month, value: 1, to: today)!),
        ]

        // Add weekday keywords
        let weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        var allKeywords = dateKeywords
        for (i, name) in weekdays.enumerated() {
            let weekdayNum = i + 1 // 1=Sunday
            if let nextOccurrence = cal.nextDate(after: Date(), matching: DateComponents(weekday: weekdayNum), matchingPolicy: .nextTime) {
                allKeywords.append((name, cal.startOfDay(for: nextOccurrence)))
                allKeywords.append(("next \(name)", cal.startOfDay(for: cal.date(byAdding: .weekOfYear, value: 1, to: nextOccurrence)!)))
            }
        }

        // Sort by length descending to match longest pattern first
        let sortedKeywords = allKeywords.sorted { $0.0.count > $1.0.count }

        for (keyword, date) in sortedKeywords {
            if let range = lowered.range(of: keyword) {
                result.dueDate = date
                text.removeSubrange(range)
                text = text.trimmingCharacters(in: .whitespaces)
                break
            }
        }

        // If no keyword matched, try NSDataDetector
        if result.dueDate == nil {
            if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
                let matches = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
                if let match = matches.first, let date = match.date {
                    result.dueDate = date
                    if let range = Range(match.range, in: text) {
                        text.removeSubrange(range)
                        text = text.trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }

        // Clean up extra whitespace
        result.title = text.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return result
    }
}
