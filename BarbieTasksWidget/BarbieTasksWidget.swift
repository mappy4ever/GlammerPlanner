import WidgetKit
import SwiftUI

// MARK: - Timeline Entries

struct TaskEntry: TimelineEntry {
    let date: Date
    let todayTasks: [WidgetTask]
    let completedToday: Int
    let totalToday: Int
}

struct WeekEntry: TimelineEntry {
    let date: Date
    let days: [WeekDay]
}

struct WeekDay: Identifiable {
    let id = UUID()
    let date: Date
    let label: String       // "Mon", "Tue"...
    let dayNumber: String   // "14"
    let isToday: Bool
    let taskCount: Int
    let doneCount: Int
    let topTasks: [String]  // up to 3 task titles
}

struct WidgetTask: Identifiable {
    let id: UUID
    let title: String
    let isOverdue: Bool
    let priority: Int
}

// MARK: - Today Provider

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(
            date: Date(),
            todayTasks: [
                WidgetTask(id: UUID(), title: "Plan something fabulous", isOverdue: false, priority: 0),
                WidgetTask(id: UUID(), title: "Conquer the world", isOverdue: false, priority: 3),
            ],
            completedToday: 3,
            totalToday: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> TaskEntry {
        let tasks = WidgetDataLoader.loadTasks()
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!

        let todayTasks = tasks.filter { task in
            guard !task.isTrashed, !task.isDone else { return false }
            guard let due = task.dueDate else { return false }
            return due < tomorrow
        }

        let completedToday = tasks.filter { task in
            guard let doneAt = task.doneAt else { return false }
            return doneAt >= today && doneAt < tomorrow
        }.count

        let widgetTasks = todayTasks.prefix(6).map { task in
            WidgetTask(
                id: task.id,
                title: task.title,
                isOverdue: task.dueDate.map { $0 < today } ?? false,
                priority: task.priority.rawValue
            )
        }

        return TaskEntry(
            date: Date(),
            todayTasks: Array(widgetTasks),
            completedToday: completedToday,
            totalToday: todayTasks.count + completedToday
        )
    }
}

// MARK: - Week Provider

struct WeekProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeekEntry {
        WeekEntry(date: Date(), days: buildPlaceholderWeek())
    }

    func getSnapshot(in context: Context, completion: @escaping (WeekEntry) -> Void) {
        completion(loadWeekEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeekEntry>) -> Void) {
        let entry = loadWeekEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadWeekEntry() -> WeekEntry {
        let tasks = WidgetDataLoader.loadTasks()
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Find start of week (Sunday)
        let weekday = cal.component(.weekday, from: today)
        let startOfWeek = cal.date(byAdding: .day, value: -(weekday - 1), to: today)!

        var days: [WeekDay] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"

        for i in 0..<7 {
            let day = cal.date(byAdding: .day, value: i, to: startOfWeek)!
            let dayStart = cal.startOfDay(for: day)
            let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!

            let dayTasks = tasks.filter { task in
                guard !task.isTrashed else { return false }
                guard let due = task.dueDate else { return false }
                return due >= dayStart && due < dayEnd
            }

            let doneCount = dayTasks.filter(\.isDone).count
            let pendingTitles = dayTasks.filter { !$0.isDone }.prefix(3).map(\.title)

            days.append(WeekDay(
                date: day,
                label: formatter.string(from: day),
                dayNumber: dayFormatter.string(from: day),
                isToday: cal.isDate(day, inSameDayAs: today),
                taskCount: dayTasks.count,
                doneCount: doneCount,
                topTasks: Array(pendingTitles)
            ))
        }

        return WeekEntry(date: Date(), days: days)
    }

    private func buildPlaceholderWeek() -> [WeekDay] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let startOfWeek = cal.date(byAdding: .day, value: -(weekday - 1), to: today)!
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"

        return (0..<7).map { i in
            let day = cal.date(byAdding: .day, value: i, to: startOfWeek)!
            return WeekDay(
                date: day,
                label: formatter.string(from: day),
                dayNumber: dayFormatter.string(from: day),
                isToday: cal.isDate(day, inSameDayAs: today),
                taskCount: Int.random(in: 0...4),
                doneCount: Int.random(in: 0...2),
                topTasks: ["Sample task"]
            )
        }
    }
}

// MARK: - Shared Data Loader

enum WidgetDataLoader {
    static func loadTasks() -> [WidgetData.Task] {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("BarbieTasks", isDirectory: true)
        let fileURL = dir.appendingPathComponent("data.json")

        guard let json = try? Data(contentsOf: fileURL),
              let data = try? JSONDecoder().decode(WidgetData.self, from: json)
        else { return [] }

        return data.tasks
    }
}

// Minimal decodable for widget
struct WidgetData: Codable {
    struct Task: Codable {
        let id: UUID
        let title: String
        let isDone: Bool
        let doneAt: Date?
        let dueDate: Date?
        let isTrashed: Bool
        let priority: Priority

        enum Priority: Int, Codable {
            case none = 0, low = 1, medium = 2, high = 3
        }
    }
    let tasks: [Task]
}

// MARK: - Today Widget Views

struct SmallWidgetView: View {
    let entry: TaskEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Today")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#D4577A"))
                Spacer()
                Text("\(entry.completedToday)/\(entry.totalToday)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#B8949E"))
            }

            if entry.todayTasks.isEmpty {
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(Color(hex: "#D4577A"))
                    Text("All clear!")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "#B8949E"))
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(entry.todayTasks.prefix(4)) { task in
                    HStack(spacing: 6) {
                        Circle()
                            .stroke(priorityColor(task.priority), lineWidth: 1.5)
                            .frame(width: 12, height: 12)
                        Text(task.title)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(task.isOverdue ? Color(hex: "#C25050") : Color(hex: "#3D2B33"))
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(hex: "#FDF5F7")
        }
    }
}

struct MediumWidgetView: View {
    let entry: TaskEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: progress ring
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color(hex: "#F7E3E8"), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: entry.totalToday > 0 ? Double(entry.completedToday) / Double(entry.totalToday) : 0)
                        .stroke(Color(hex: "#D4577A"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(entry.completedToday)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#D4577A"))
                }
                .frame(width: 56, height: 56)

                Text("done today")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "#B8949E"))
            }
            .frame(width: 80)

            // Right: task list
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Tasks")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#D4577A"))

                if entry.todayTasks.isEmpty {
                    Text("Nothing due \u{2014} enjoy!")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "#B8949E"))
                } else {
                    ForEach(entry.todayTasks.prefix(5)) { task in
                        HStack(spacing: 6) {
                            Circle()
                                .stroke(priorityColor(task.priority), lineWidth: 1.5)
                                .frame(width: 12, height: 12)
                            Text(task.title)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(task.isOverdue ? Color(hex: "#C25050") : Color(hex: "#3D2B33"))
                                .lineLimit(1)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(hex: "#FDF5F7")
        }
    }
}

// MARK: - Weekly Calendar Widget View

struct WeeklyCalendarWidgetView: View {
    let entry: WeekEntry

    var body: some View {
        VStack(spacing: 6) {
            // Header
            HStack {
                Text("This Week")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#D4577A"))
                Spacer()
                let totalTasks = entry.days.reduce(0) { $0 + $1.taskCount }
                let totalDone = entry.days.reduce(0) { $0 + $1.doneCount }
                Text("\(totalDone)/\(totalTasks)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#B8949E"))
            }

            // Day columns
            HStack(spacing: 4) {
                ForEach(entry.days) { day in
                    VStack(spacing: 3) {
                        Text(day.label)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(day.isToday ? Color(hex: "#D4577A") : Color(hex: "#B8949E"))

                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(day.isToday ? Color(hex: "#D4577A").opacity(0.12) : Color(hex: "#F7E3E8").opacity(0.5))

                            VStack(spacing: 2) {
                                Text(day.dayNumber)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(day.isToday ? Color(hex: "#D4577A") : Color(hex: "#3D2B33"))

                                if day.taskCount > 0 {
                                    // Mini dots for tasks
                                    HStack(spacing: 2) {
                                        let pending = day.taskCount - day.doneCount
                                        ForEach(0..<min(pending, 3), id: \.self) { _ in
                                            Circle()
                                                .fill(Color(hex: "#D4577A"))
                                                .frame(width: 4, height: 4)
                                        }
                                        ForEach(0..<min(day.doneCount, 3), id: \.self) { _ in
                                            Circle()
                                                .fill(Color(hex: "#C8E6C9"))
                                                .frame(width: 4, height: 4)
                                        }
                                    }

                                    Text("\(day.taskCount)")
                                        .font(.system(size: 8, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color(hex: "#B8949E"))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color(hex: "#FDF5F7")
        }
    }
}

struct LargeWeeklyWidgetView: View {
    let entry: WeekEntry

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Weekly Overview")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#D4577A"))
                Spacer()
                let totalTasks = entry.days.reduce(0) { $0 + $1.taskCount }
                let totalDone = entry.days.reduce(0) { $0 + $1.doneCount }
                Text("\(totalDone)/\(totalTasks) done")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#B8949E"))
            }

            // Days with task previews
            ForEach(entry.days) { day in
                HStack(spacing: 8) {
                    // Day label
                    VStack(spacing: 1) {
                        Text(day.label)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(day.isToday ? Color(hex: "#D4577A") : Color(hex: "#B8949E"))
                        Text(day.dayNumber)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(day.isToday ? Color(hex: "#D4577A") : Color(hex: "#3D2B33"))
                    }
                    .frame(width: 32)

                    if day.isToday {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "#D4577A"))
                            .frame(width: 2)
                    }

                    // Tasks preview
                    if day.topTasks.isEmpty && day.taskCount == 0 {
                        Text("\u{2014}")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(hex: "#D8C8D0"))
                    } else {
                        VStack(alignment: .leading, spacing: 1) {
                            ForEach(day.topTasks.prefix(2), id: \.self) { title in
                                Text(title)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color(hex: "#3D2B33"))
                                    .lineLimit(1)
                            }
                            if day.taskCount > day.topTasks.count {
                                Text("+\(day.taskCount - day.topTasks.count) more")
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color(hex: "#B8949E"))
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    // Done count
                    if day.doneCount > 0 {
                        Text("\(day.doneCount)\u{2713}")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#6BAF5F"))
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(
                    day.isToday
                    ? RoundedRectangle(cornerRadius: 6).fill(Color(hex: "#D4577A").opacity(0.08))
                    : nil
                )
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(hex: "#FDF5F7")
        }
    }
}

// MARK: - Widget Configurations

struct SlayListTodayWidget: Widget {
    let kind: String = "SlayListTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            SmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Tasks")
        .description("Your tasks for today at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SlayListWeekWidget: Widget {
    let kind: String = "SlayListWeekWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeekProvider()) { entry in
            WeeklyCalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("Weekly Calendar")
        .description("Your week at a glance \u{2014} tasks by day.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

@main
struct SlayListWidgets: WidgetBundle {
    var body: some Widget {
        SlayListTodayWidget()
        SlayListWeekWidget()
    }
}

// MARK: - Priority Color Helper

private func priorityColor(_ p: Int) -> Color {
    switch p {
    case 3: return Color(hex: "#D4577A")
    case 2: return Color(hex: "#D4956B")
    case 1: return Color(hex: "#6BA3C9")
    default: return Color(hex: "#EFCDD5")
    }
}

// Color hex init for widget (self-contained)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
