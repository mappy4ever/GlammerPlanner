import Foundation

/// Parses natural language from quick-add input.
/// "Buy milk tomorrow 3pm !!" → title="Buy milk", dueDate=tomorrow 3pm, priority=medium
/// "Meeting next friday #Work @urgent" → title="Meeting", dueDate=next friday, project="Work", tags=["urgent"]
struct NaturalDateParser {

    struct ParseResult {
        var title: String
        var dueDate: Date?
        var priority: Int = 0
        var projectName: String?
        var tagNames: [String] = []
    }

    typealias Result = ParseResult

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
            ("end of week", cal.nextDate(after: today, matching: DateComponents(weekday: 6), matchingPolicy: .nextTime)!),
            ("this weekend", cal.nextDate(after: today, matching: DateComponents(weekday: 7), matchingPolicy: .nextTime)!),
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

        // Relative dates: "in 3 days", "in 2 weeks", "in 1 month"
        if result.dueDate == nil {
            if let match = lowered.range(of: #"in (\d+) (day|days|week|weeks|month|months)"#, options: .regularExpression) {
                let matched = String(lowered[match])
                let parts = matched.split(separator: " ")
                if parts.count == 3, let num = Int(parts[1]) {
                    let unit = String(parts[2])
                    var date: Date?
                    if unit.hasPrefix("day") {
                        date = cal.date(byAdding: .day, value: num, to: today)
                    } else if unit.hasPrefix("week") {
                        date = cal.date(byAdding: .weekOfYear, value: num, to: today)
                    } else if unit.hasPrefix("month") {
                        date = cal.date(byAdding: .month, value: num, to: today)
                    }
                    if let date {
                        result.dueDate = date
                        text.removeSubrange(match)
                        text = text.trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        }

        // Time parsing: "at 3pm", "at 2:30pm", "3pm", "14:00"
        if let timeMatch = lowered.range(of: #"(?:at )?(\d{1,2})(?::(\d{2}))?\s*(am|pm)"#, options: .regularExpression) {
            let matched = String(lowered[timeMatch])
            let cleaned = matched.replacingOccurrences(of: "at ", with: "")
            if let parsedTime = parseTime(cleaned) {
                let baseDate = result.dueDate ?? today
                result.dueDate = cal.date(bySettingHour: parsedTime.hour, minute: parsedTime.minute, second: 0, of: baseDate)
                text.removeSubrange(timeMatch)
                text = text.trimmingCharacters(in: .whitespaces)
            }
        } else if result.dueDate == nil, let timeMatch24 = lowered.range(of: #"(?:at )(\d{1,2}):(\d{2})"#, options: .regularExpression) {
            let matched = String(lowered[timeMatch24])
            let digits = matched.replacingOccurrences(of: "at ", with: "").split(separator: ":")
            if digits.count == 2, let h = Int(digits[0]), let m = Int(digits[1]), h < 24, m < 60 {
                result.dueDate = cal.date(bySettingHour: h, minute: m, second: 0, of: today)
                text.removeSubrange(timeMatch24)
                text = text.trimmingCharacters(in: .whitespaces)
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

    private static func parseTime(_ str: String) -> (hour: Int, minute: Int)? {
        let cleaned = str.trimmingCharacters(in: .whitespaces).lowercased()
        let isPM = cleaned.hasSuffix("pm")
        let isAM = cleaned.hasSuffix("am")
        guard isPM || isAM else { return nil }

        let digits = cleaned.replacingOccurrences(of: "am", with: "").replacingOccurrences(of: "pm", with: "").trimmingCharacters(in: .whitespaces)
        let parts = digits.split(separator: ":")
        guard let hour = Int(parts[0]) else { return nil }
        let minute = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0

        var h = hour
        if isPM && h != 12 { h += 12 }
        if isAM && h == 12 { h = 0 }
        guard h < 24, minute < 60 else { return nil }
        return (h, minute)
    }
}
