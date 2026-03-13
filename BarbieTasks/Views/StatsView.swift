import SwiftUI
import Charts

struct StatsView: View {
    @Environment(Store.self) private var store

    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Top stat cards row
                HStack(spacing: 12) {
                    statCard(
                        title: "Current Streak",
                        value: "\(store.currentStreak)",
                        unit: store.currentStreak == 1 ? "day" : "days",
                        icon: "flame.fill",
                        color: .barbiePink
                    )

                    statCard(
                        title: "Completed Today",
                        value: "\(store.completedToday)",
                        unit: store.completedToday == 1 ? "task" : "tasks",
                        icon: "checkmark.circle.fill",
                        color: .barbieRose
                    )

                    statCard(
                        title: "Total Completed",
                        value: "\(totalCompleted)",
                        unit: totalCompleted == 1 ? "task" : "tasks",
                        icon: "trophy.fill",
                        color: .gold
                    )

                    statCard(
                        title: "Daily Average",
                        value: formattedAverage,
                        unit: "per day",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .barbieDeep
                    )
                }

                // Second row of stat cards
                HStack(spacing: 12) {
                    statCard(
                        title: "Best Streak",
                        value: "\(store.bestStreak)",
                        unit: store.bestStreak == 1 ? "day" : "days",
                        icon: "star.fill",
                        color: .gold
                    )

                    statCard(
                        title: "Completion Rate",
                        value: "\(Int(store.completionRate * 100))%",
                        unit: "of all tasks",
                        icon: "chart.pie.fill",
                        color: .barbiePink
                    )

                    statCard(
                        title: "Overdue",
                        value: "\(store.overdueCount)",
                        unit: store.overdueCount == 1 ? "task" : "tasks",
                        icon: "exclamationmark.triangle.fill",
                        color: store.overdueCount > 0 ? Color(hex: "#C25050") : .barbieRose
                    )

                    statCard(
                        title: "Active Tasks",
                        value: "\(store.incompleteTasks.count)",
                        unit: "remaining",
                        icon: "list.bullet",
                        color: .barbieDeep
                    )
                }

                // Daily completion chart
                dailyCompletionCard

                // Completion by project chart
                projectCompletionCard
            }
            .padding(16)
        }
        .background(Color.blush)
    }

    // MARK: - Stat Card

    private func statCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkPrimary)

            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkSecondary)

                Text(unit)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blushMid)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.petal, lineWidth: 1)
                )
        )
    }

    // MARK: - Daily Completion Chart

    private var dailyCompletionCard: some View {
        let data = store.completedPerDay(last: 14)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.barbiePink)
                Text("Daily Completions")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkPrimary)
                Spacer()
                Text("Last 14 days")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkMuted)
            }

            Chart(data, id: \.0) { item in
                BarMark(
                    x: .value("Date", item.0, unit: .day),
                    y: .value("Tasks", item.1)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.barbiePink, .barbieRose],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.petalLight)
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.inkMuted)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.petalLight)
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.inkMuted)
                }
            }
            .chartPlotStyle { plot in
                plot.background(Color.blush.opacity(0.5))
            }
            .frame(height: 180)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blushMid)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.petal, lineWidth: 1)
                )
        )
    }

    // MARK: - Project Completion Chart

    private var projectCompletionCard: some View {
        let projectData = completionByProject

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.barbieRose)
                Text("Completion by Project")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkPrimary)
                Spacer()
            }

            if projectData.isEmpty {
                Text("Complete some tasks to see project stats")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart(projectData, id: \.name) { item in
                    BarMark(
                        x: .value("Completed", item.count),
                        y: .value("Project", item.name)
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                    .annotation(position: .trailing, spacing: 4) {
                        Text("\(item.count)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.inkSecondary)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.petalLight)
                        AxisValueLabel()
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.inkMuted)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.inkPrimary)
                    }
                }
                .chartPlotStyle { plot in
                    plot.background(Color.blush.opacity(0.5))
                }
                .frame(height: max(CGFloat(projectData.count) * 36, 80))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blushMid)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.petal, lineWidth: 1)
                )
        )
    }

    // MARK: - Computed Data

    private var totalCompleted: Int {
        store.tasks.filter { $0.isDone }.count
    }

    private var formattedAverage: String {
        let data = store.completedPerDay(last: 14)
        let total = data.reduce(0) { $0 + $1.1 }
        let avg = data.isEmpty ? 0.0 : Double(total) / Double(data.count)
        return String(format: "%.1f", avg)
    }

    private struct ProjectStat: Identifiable {
        let name: String
        let count: Int
        let color: Color
        var id: String { name }
    }

    private var completionByProject: [ProjectStat] {
        let completedTasks = store.tasks.filter { $0.isDone && !$0.isTrashed }

        // Group by project
        var counts: [UUID?: Int] = [:]
        for task in completedTasks {
            counts[task.projectId, default: 0] += 1
        }

        var stats: [ProjectStat] = []

        // Inbox (nil projectId)
        if let inboxCount = counts[nil], inboxCount > 0 {
            stats.append(ProjectStat(name: "Inbox", count: inboxCount, color: .barbiePink))
        }

        // Named projects
        for project in store.projects {
            if let count = counts[project.id], count > 0 {
                stats.append(ProjectStat(name: project.title, count: count, color: project.color))
            }
        }

        return stats.sorted { $0.count > $1.count }
    }
}
