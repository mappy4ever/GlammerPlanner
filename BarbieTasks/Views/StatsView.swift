import SwiftUI
import Charts

struct StatsView: View {
    @Environment(Store.self) private var store

    @State private var appeared = false
    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Motivational header
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.barbiePink)
                        .symbolEffect(.pulse)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(statsGreeting)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.barbieDeep, .barbiePink, .barbieRose],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                        Text(statsSubtitle)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.inkMuted)
                    }
                    Spacer()
                }
                .padding(.horizontal, 4)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                // Daily goal progress ring
                dailyGoalCard
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)

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
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                // Streak calendar (GitHub-style)
                streakCalendar
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                // Medal Gallery
                medalGallery
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                // Daily completion chart
                dailyCompletionCard
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                // Completion by project chart
                projectCompletionCard
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }
            .padding(16)
        }
        .background(Color.blush)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Stat Card

    private func statCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(color)
                .symbolEffect(.pulse, options: .repeating, value: icon == "flame.fill" && store.currentStreak >= 3)

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

    // MARK: - Daily Goal Card

    private var dailyGoalCard: some View {
        let goal = store.profile.dailyGoal
        let done = store.completedToday
        let progress = store.dailyGoalProgress
        let goalMet = done >= goal

        return HStack(spacing: 20) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.petal, lineWidth: 6)
                    .frame(width: 70, height: 70)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: goalMet ? [.barbieRose, .barbiePink] : [.barbiePink, .barbieDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)

                VStack(spacing: 0) {
                    Text("\(done)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(goalMet ? Color.barbiePink : Color.inkPrimary)
                    Text("/\(goal)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.inkMuted)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Goal")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkPrimary)

                if goalMet {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.barbiePink)
                        Text("Goal reached!")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.barbiePink)
                    }
                } else {
                    Text("\(goal - done) more to go")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.inkSecondary)
                }

                // Mini progress dots
                HStack(spacing: 3) {
                    ForEach(0..<min(goal, 20), id: \.self) { i in
                        Circle()
                            .fill(i < done ? Color.barbiePink : Color.petal)
                            .frame(width: 6, height: 6)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6).delay(Double(i) * 0.03), value: done)
                    }
                    if goal > 20 {
                        Text("+\(goal - 20)")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.inkMuted)
                    }
                }
            }

            Spacer()

            // Streak flame
            if store.currentStreak > 0 {
                VStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.barbiePink, Color(hex: "#FF6B6B")],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .symbolEffect(.bounce, value: store.currentStreak)
                    Text("\(store.currentStreak)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkPrimary)
                    Text("streak")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.inkMuted)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.blushMid)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(goalMet ? Color.barbiePink.opacity(0.3) : Color.petal, lineWidth: 1)
                )
        )
    }

    // MARK: - Medal Gallery

    private var medalGallery: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.gold)
                Text("Medals")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkPrimary)

                Spacer()

                Text("\(store.profile.unlockedCount)/\(store.profile.totalMedals)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkMuted)
            }

            ForEach(MedalCategory.allCases, id: \.rawValue) { category in
                let medals = MedalId.allCases.filter { $0.definition.category == category }
                let unlockedInCategory = medals.filter { store.profile.hasMedal($0) }.count

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: category.icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.inkSecondary)
                        Text(category.label)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.inkSecondary)
                        Spacer()
                        Text("\(unlockedInCategory)/\(medals.count)")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.inkMuted)
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(medals, id: \.rawValue) { medalId in
                            medalBadge(medalId: medalId)
                        }
                    }
                }
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

    private func medalBadge(medalId: MedalId) -> some View {
        let def = medalId.definition
        let unlocked = store.profile.hasMedal(medalId)
        let unlock = store.profile.unlockedMedals.first { $0.medalId == medalId }

        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(
                        unlocked
                        ? LinearGradient(colors: def.tier.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.petal.opacity(0.3), Color.petal.opacity(0.15)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 40, height: 40)
                    .shadow(color: unlocked ? def.tier.glowColor.opacity(0.3) : .clear, radius: 6, y: 2)

                Image(systemName: unlocked ? def.icon : "lock.fill")
                    .font(.system(size: unlocked ? 16 : 12, weight: .semibold))
                    .foregroundStyle(unlocked ? .white : Color.inkMuted.opacity(0.3))
            }

            Text(unlocked ? def.title : "???")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(unlocked ? Color.inkPrimary : Color.inkMuted.opacity(0.4))
                .lineLimit(1)

            Text(unlocked ? def.description : "")
                .font(.system(size: 7, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(unlocked ? def.tier.glowColor.opacity(0.06) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(unlocked ? def.tier.glowColor.opacity(0.2) : Color.clear, lineWidth: 1)
        )
        .help(unlocked
              ? "\(def.title) — \(def.description)\nUnlocked: \(unlock?.unlockedAt.formatted(.dateTime.month(.abbreviated).day().year()) ?? "")"
              : def.description
        )
    }

    // MARK: - Streak Calendar (GitHub-style contribution graph)

    private var streakCalendar: some View {
        let weeks = 13 // ~3 months
        let totalDays = weeks * 7
        let today = calendar.startOfDay(for: Date())
        let completionMap = buildCompletionMap(days: totalDays)

        // Figure out how many days back from today to the start of the week
        let todayWeekday = calendar.component(.weekday, from: today)
        let daysFromWeekStart = (todayWeekday - calendar.firstWeekday + 7) % 7

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.barbiePink)
                Text("Activity")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkPrimary)
                Spacer()
                Text("Last \(weeks) weeks")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkMuted)
            }

            // Day labels on left + grid
            HStack(alignment: .top, spacing: 4) {
                // Weekday labels
                VStack(spacing: 2) {
                    ForEach(0..<7, id: \.self) { row in
                        let dayIndex = (calendar.firstWeekday - 1 + row) % 7
                        let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
                        Text(row % 2 == 0 ? symbols[dayIndex] : "")
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.inkMuted)
                            .frame(width: 14, height: 11)
                    }
                }

                // Grid of squares
                HStack(spacing: 2) {
                    ForEach(0..<weeks, id: \.self) { weekIndex in
                        VStack(spacing: 2) {
                            ForEach(0..<7, id: \.self) { dayIndex in
                                let daysAgo = (weeks - 1 - weekIndex) * 7 + (6 - dayIndex) - (6 - daysFromWeekStart)
                                let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
                                let count = completionMap[calendar.startOfDay(for: date)] ?? 0
                                let isFuture = date > today

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(isFuture ? Color.clear : streakColor(count: count))
                                    .frame(width: 11, height: 11)
                                    .help(isFuture ? "" : "\(count) tasks \u{2013} \(date.formatted(.dateTime.month(.abbreviated).day()))")
                            }
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: 4) {
                Spacer()
                Text("Less")
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkMuted)
                ForEach([0, 1, 3, 5, 8], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(streakColor(count: level))
                        .frame(width: 11, height: 11)
                }
                Text("More")
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkMuted)
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

    private func streakColor(count: Int) -> Color {
        if count == 0 { return Color.petal.opacity(0.3) }
        if count <= 1 { return Color.barbiePink.opacity(0.25) }
        if count <= 3 { return Color.barbiePink.opacity(0.45) }
        if count <= 5 { return Color.barbiePink.opacity(0.7) }
        return Color.barbiePink
    }

    private func buildCompletionMap(days: Int) -> [Date: Int] {
        let cal = Calendar.current
        var map: [Date: Int] = [:]
        for task in store.tasks where task.isDone {
            guard let doneAt = task.doneAt else { continue }
            let day = cal.startOfDay(for: doneAt)
            map[day, default: 0] += 1
        }
        return map
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

    private var statsGreeting: String {
        let today = store.completedToday
        if today >= 10 { return "You're a productivity LEGEND today!" }
        if today >= 5 { return "You're on fire today!" }
        if today >= 3 { return "Great momentum, keep going!" }
        if today >= 1 { return "You've started strong!" }
        return "Ready to win today?"
    }

    private var statsSubtitle: String {
        let streak = store.currentStreak
        if streak >= 7 { return "\(streak)-day streak! You're unstoppable!" }
        if streak >= 3 { return "\(streak)-day streak! Keep the fire going!" }
        if streak >= 1 { return "\(streak)-day streak active" }
        return "Complete a task to start your streak"
    }

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
