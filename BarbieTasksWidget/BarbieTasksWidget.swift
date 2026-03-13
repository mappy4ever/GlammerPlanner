import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct TaskEntry: TimelineEntry {
    let date: Date
    let todayTasks: [WidgetTask]
    let completedToday: Int
    let totalToday: Int
}

struct WidgetTask: Identifiable {
    let id: UUID
    let title: String
    let isOverdue: Bool
    let priority: Int
}

struct Provider: TimelineProvider {
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
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> TaskEntry {
        // Read from shared App Group container
        // In production, use App Groups to share data between app and widget
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("BarbieTasks", isDirectory: true)
        let fileURL = dir.appendingPathComponent("data.json")

        guard let json = try? Data(contentsOf: fileURL),
              let data = try? JSONDecoder().decode(WidgetData.self, from: json)
        else {
            return TaskEntry(date: Date(), todayTasks: [], completedToday: 0, totalToday: 0)
        }

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!

        let todayTasks = data.tasks.filter { task in
            guard !task.isTrashed else { return false }
            guard !task.isDone else { return false }
            guard let due = task.dueDate else { return false }
            return due < tomorrow
        }

        let completedToday = data.tasks.filter { task in
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

// Minimal decodable for widget
private struct WidgetData: Codable {
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

// MARK: - Widget Views

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

    private func priorityColor(_ p: Int) -> Color {
        switch p {
        case 3: return Color(hex: "#D4577A")
        case 2: return Color(hex: "#D4956B")
        case 1: return Color(hex: "#6BA3C9")
        default: return Color(hex: "#EFCDD5")
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
                    Text("Nothing due — enjoy!")
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

    private func priorityColor(_ p: Int) -> Color {
        switch p {
        case 3: return Color(hex: "#D4577A")
        case 2: return Color(hex: "#D4956B")
        case 1: return Color(hex: "#6BA3C9")
        default: return Color(hex: "#EFCDD5")
        }
    }
}

// MARK: - Widget Configuration

struct BarbieTasksWidget: Widget {
    let kind: String = "BarbieTasksWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(macOS 14.0, *) {
                switch entry.todayTasks.count {
                default:
                    SmallWidgetView(entry: entry)
                }
            }
        }
        .configurationDisplayName("Glammer Planner")
        .description("My Slay List \u{2014} today\u{2019}s tasks at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
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
