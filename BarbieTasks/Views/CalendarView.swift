import SwiftUI
import EventKit

// MARK: - Calendar View Mode

private enum CalendarMode: String, CaseIterable {
    case month, week

    var label: String {
        switch self {
        case .month: "Month"
        case .week:  "Week"
        }
    }

    var icon: String {
        switch self {
        case .month: "calendar"
        case .week:  "calendar.day.timeline.left"
        }
    }
}

// MARK: - Main Calendar View

struct CalendarView: View {
    @Environment(Store.self) private var store
    @Environment(AppSettings.self) private var settings

    @State private var calendarMode: CalendarMode = .week
    @State private var displayedMonth: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showCalendarEvents: Bool = true
    @State private var calendarEvents: [Date: [EKEvent]] = [:]
    @State private var monthTransitionDirection: Edge = .trailing
    @State private var monthId = UUID()
    @State private var dropTargetDate: Date?
    @State private var weekStart: Date = Calendar.current.startOfDay(for: Date())
    @State private var useNext7Days: Bool = true

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = settings.calendarStartDay
        return cal
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    private var orderedWeekdaySymbols: [String] {
        let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
        let startIndex = settings.calendarStartDay - 1
        return Array(symbols[startIndex...]) + Array(symbols[..<startIndex])
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mode toggle bar
            modeToggle
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 6)

            if calendarMode == .month {
                monthView
            } else {
                weeklyView
            }
        }
        .background(Color.blush)
        .onAppear {
            requestCalendarAccessIfNeeded()
            loadCalendarEvents()
            weekStart = computeWeekStart()
        }
        .onChange(of: displayedMonth) { _, _ in
            loadCalendarEvents()
        }
        .animation(.smooth(duration: 0.35), value: calendarMode)
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        HStack(spacing: 0) {
            ForEach(CalendarMode.allCases, id: \.self) { mode in
                Button {
                    calendarMode = mode
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(mode.label)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(calendarMode == mode ? .white : Color.inkSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(calendarMode == mode ? Color.barbiePink : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if calendarMode == .week {
                // Next 7 Days vs Calendar Week toggle
                Button {
                    withAnimation(.smooth(duration: 0.3)) {
                        useNext7Days.toggle()
                        weekStart = computeWeekStart()
                    }
                } label: {
                    Text(useNext7Days ? "Next 7 Days" : "This Week")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.barbiePink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.barbiePink.opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Month View (existing)

    private var monthView: some View {
        VStack(spacing: 0) {
            monthHeader
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)

            weekdayHeader
                .padding(.horizontal, 16)

            calendarGrid
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .id(monthId)
                .transition(.asymmetric(
                    insertion: .move(edge: monthTransitionDirection).combined(with: .opacity),
                    removal: .move(edge: monthTransitionDirection == .trailing ? .leading : .trailing).combined(with: .opacity)
                ))

            Divider().foregroundStyle(Color.petal)

            calendarToggle
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            Divider().foregroundStyle(Color.petalLight)

            selectedDayContent
        }
    }

    // ============================================================
    // MARK: - Weekly View (NEW)
    // ============================================================

    private var weekDays: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private func computeWeekStart() -> Date {
        if useNext7Days {
            return calendar.startOfDay(for: Date())
        } else {
            // Start of the current calendar week
            let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
            return calendar.date(from: comps) ?? calendar.startOfDay(for: Date())
        }
    }

    private var weeklyView: some View {
        VStack(spacing: 0) {
            // Week navigation
            weekNavHeader
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)

            // 7 columns — Kanban-style
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(weekDays.enumerated()), id: \.element) { index, date in
                    if index > 0 {
                        Rectangle()
                            .fill(Color.petal.opacity(0.35))
                            .frame(width: 1)
                            .padding(.vertical, 6)
                    }
                    weekDayColumn(date)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 16)
        }
    }

    private var weekNavHeader: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    weekStart = calendar.date(byAdding: .day, value: -7, to: weekStart)!
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.barbiePink)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(weekRangeLabel)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkPrimary)

            Spacer()

            // Today button
            if !weekDays.contains(where: { calendar.isDateInToday($0) }) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        weekStart = computeWeekStart()
                    }
                } label: {
                    Text("Today")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.barbiePink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.barbiePink.opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    weekStart = calendar.date(byAdding: .day, value: 7, to: weekStart)!
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.barbiePink)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var weekRangeLabel: String {
        guard let first = weekDays.first, let last = weekDays.last else { return "" }
        let startStr = first.formatted(.dateTime.month(.abbreviated).day())
        let endStr = last.formatted(.dateTime.month(.abbreviated).day())
        return "\(startStr) \u{2013} \(endStr)"
    }

    // MARK: - Week Day Column (Kanban-style)

    @ViewBuilder
    private func weekDayColumn(_ date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let dayTasks = store.tasksForDay(date)
        let done = dayTasks.filter(\.isDone).count
        let isDropTarget = dropTargetDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false

        VStack(alignment: .leading, spacing: 0) {
            // Column header
            VStack(spacing: 2) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(isToday ? Color.barbiePink : Color.inkMuted)
                    .tracking(0.5)

                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 18, weight: isToday ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isToday ? .white : Color.inkPrimary)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle().fill(isToday ? Color.barbiePink : Color.clear)
                    )

                if !dayTasks.isEmpty {
                    Text("\(done)/\(dayTasks.count)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(done == dayTasks.count ? Color.barbiePink : Color.inkMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isToday ? Color.barbiePink.opacity(0.06) : Color.clear)

            // Separator
            Rectangle()
                .fill(isToday ? Color.barbiePink.opacity(0.3) : Color.petal.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 4)

            // Tasks
            ScrollView(.vertical) {
                LazyVStack(spacing: 4) {
                    if dayTasks.isEmpty {
                        Text("\u{2014}")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.inkMuted.opacity(0.3))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 16)
                    } else {
                        ForEach(dayTasks) { task in
                            weekTaskCard(task: task)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            }
        }
        .frame(minWidth: 50, maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isDropTarget ? Color.barbiePink.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .background(isDropTarget ? Color.barbiePink.opacity(0.05) : Color.clear)
        .animation(.smooth(duration: 0.2), value: isDropTarget)
        .dropDestination(for: String.self) { items, _ in
            guard let idString = items.first, let taskId = UUID(uuidString: idString) else { return false }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                store.moveTaskToDate(taskId: taskId, date: date)
                dropTargetDate = nil
            }
            return true
        } isTargeted: { targeted in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                dropTargetDate = targeted ? date : nil
            }
        }
    }

    // Compact task card for weekly columns
    private func weekTaskCard(task: BarbieTask) -> some View {
        HStack(spacing: 5) {
            // Checkbox
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                    store.toggleTask(task.id)
                }
            } label: {
                ZStack {
                    let doneColor = Color.accentColor(for: task.id)
                    Circle()
                        .stroke(task.isDone ? doneColor : checkboxColor(for: task), lineWidth: 1.5)
                        .frame(width: 14, height: 14)

                    if task.isDone {
                        Circle().fill(doneColor).frame(width: 14, height: 14)
                        Image(systemName: "checkmark")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(task.isDone ? Color.inkMuted : Color.inkPrimary)
                .strikethrough(task.isDone, color: .inkMuted.opacity(0.5))
                .lineLimit(2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(task.isDone ? Color.blushMid.opacity(0.4) : Color.blushMid)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.petal.opacity(task.isDone ? 0.3 : 0.5), lineWidth: 0.5)
        )
        .opacity(task.isDone ? 0.75 : 1.0)
        .draggable(task.id.uuidString)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.smooth(duration: 0.3)) {
                store.selectedTaskId = task.id
            }
        }
    }

    // MARK: - Week Task Row (compact, with inline toggle)

    private func checkboxColor(for task: BarbieTask) -> Color {
        switch task.priority {
        case .high: .priHigh
        case .medium: .priMed
        case .low: .priLow
        case .none: .petal
        }
    }

    private func priorityColor(_ priority: BarbieTask.Priority) -> Color {
        switch priority {
        case .high: .priHigh
        case .medium: .priMed
        case .low: .priLow
        case .none: .petal
        }
    }

    // ============================================================
    // MARK: - Month View Components
    // ============================================================

    private var monthHeader: some View {
        HStack {
            Button {
                monthTransitionDirection = .leading
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
                    monthId = UUID()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.barbiePink)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 1) {
                Text(monthYearString)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkPrimary)
            }

            Spacer()

            if !calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month) {
                Button {
                    monthTransitionDirection = displayedMonth > Date() ? .leading : .trailing
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        displayedMonth = calendar.startOfDay(for: Date())
                        selectedDate = displayedMonth
                        monthId = UUID()
                    }
                } label: {
                    Text("Today")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.barbiePink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.barbiePink.opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Button {
                monthTransitionDirection = .trailing
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
                    monthId = UUID()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.barbiePink)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var monthYearString: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(orderedWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
        }
    }

    private var calendarGrid: some View {
        let days = daysInMonth()
        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                if let date {
                    dayCellView(date)
                } else {
                    Color.clear
                        .frame(height: 44)
                }
            }
        }
    }

    private func dayCellView(_ date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let dayTasks = store.tasksForDay(date)
        let dayEvents = calendarEvents[calendar.startOfDay(for: date)] ?? []
        let isDropTarget = dropTargetDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let completedCount = dayTasks.filter(\.isDone).count
        let totalCount = dayTasks.count

        return VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 13, weight: isToday ? .bold : .medium, design: .rounded))
                .foregroundStyle(dayCellTextColor(isToday: isToday, isSelected: isSelected))

            HStack(spacing: 2) {
                if totalCount > 0 {
                    if totalCount <= 3 {
                        taskDots(for: dayTasks)
                    } else {
                        Text("\(totalCount)")
                            .font(.system(size: 7, weight: .bold, design: .rounded))
                            .foregroundStyle(completedCount == totalCount ? Color.barbiePink : Color.inkMuted)
                            .padding(.horizontal, 3)
                            .background(
                                Capsule()
                                    .fill(completedCount == totalCount ? Color.barbiePink.opacity(0.15) : Color.petal.opacity(0.5))
                            )
                    }
                }
                if showCalendarEvents && !dayEvents.isEmpty {
                    Circle()
                        .fill(Color.gold)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(dayCellBackground(isToday: isToday, isSelected: isSelected))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isDropTarget ? Color.barbiePink : Color.clear,
                            lineWidth: isDropTarget ? 2 : 0
                        )
                )
        )
        .scaleEffect(isDropTarget ? 1.08 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isDropTarget)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                selectedDate = date
            }
        }
        .dropDestination(for: String.self) { items, _ in
            guard let idString = items.first, let taskId = UUID(uuidString: idString) else { return false }
            store.moveTaskToDate(taskId: taskId, date: date)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = date
                dropTargetDate = nil
            }
            return true
        } isTargeted: { targeted in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                dropTargetDate = targeted ? date : nil
            }
        }
    }

    private func taskDots(for tasks: [BarbieTask]) -> some View {
        let colors = tasksColors(tasks)
        return ForEach(Array(colors.prefix(3).enumerated()), id: \.offset) { _, color in
            Circle()
                .fill(color)
                .frame(width: 4, height: 4)
        }
    }

    private func tasksColors(_ tasks: [BarbieTask]) -> [Color] {
        var colors: [Color] = []
        for task in tasks {
            if task.isDone {
                if !colors.contains(.barbiePink) { colors.append(.barbiePink.opacity(0.4)) }
            } else if let proj = store.project(for: task) {
                if !colors.contains(proj.color) { colors.append(proj.color) }
            } else {
                if !colors.contains(.barbiePink) { colors.append(.barbiePink) }
            }
            if colors.count >= 3 { break }
        }
        return colors
    }

    private func dayCellTextColor(isToday: Bool, isSelected: Bool) -> Color {
        if isSelected { return .white }
        if isToday { return .barbiePink }
        return .inkPrimary
    }

    private func dayCellBackground(isToday: Bool, isSelected: Bool) -> Color {
        if isSelected { return .barbiePink }
        if isToday { return .blushMid }
        return .clear
    }

    private var calendarToggle: some View {
        HStack {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.inkSecondary)
            Text("Show Calendar Events")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkSecondary)
            Spacer()
            Toggle("", isOn: $showCalendarEvents)
                .toggleStyle(.switch)
                .tint(.barbiePink)
                .labelsHidden()
                .scaleEffect(0.8)
        }
    }

    private var selectedDayContent: some View {
        let dayTasks = store.tasksForDay(selectedDate)
        let dayEvents = (calendarEvents[calendar.startOfDay(for: selectedDate)] ?? [])
            .sorted { $0.startDate < $1.startDate }

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(selectedDateLabel)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkPrimary)

                    Spacer()

                    if !dayTasks.isEmpty {
                        let done = dayTasks.filter(\.isDone).count
                        Text("\(done)/\(dayTasks.count) done")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(done == dayTasks.count ? Color.barbiePink : Color.inkMuted)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                if !dayTasks.isEmpty {
                    sectionHeader(title: "Tasks", count: dayTasks.count)

                    ForEach(dayTasks) { task in
                        TaskRowView(task: task)
                            .draggable(task.id.uuidString)
                    }
                }

                if showCalendarEvents && !dayEvents.isEmpty {
                    sectionHeader(title: "Calendar Events", count: dayEvents.count)

                    ForEach(dayEvents, id: \.eventIdentifier) { event in
                        calendarEventRow(event)
                    }
                }

                if dayTasks.isEmpty && (!showCalendarEvents || dayEvents.isEmpty) {
                    emptyDayView
                }
            }
            .padding(.bottom, 16)
        }
    }

    private var selectedDateLabel: String {
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        }
        return selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkSecondary)
                .textCase(.uppercase)

            Text("\(count)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.barbiePink)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(Color.blushMid, in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private func calendarEventRow(_ event: EKEvent) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(cgColor: event.calendar.cgColor))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title ?? "Untitled")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkPrimary)
                    .lineLimit(1)

                Text(eventTimeString(event))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkMuted)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.petalLight.opacity(0.5))
                .padding(.horizontal, 8)
        )
    }

    private func eventTimeString(_ event: EKEvent) -> String {
        if event.isAllDay {
            return "All day"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let start = formatter.string(from: event.startDate)
        let end = formatter.string(from: event.endDate)
        return "\(start) \u{2013} \(end)"
    }

    private var emptyDayView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Color.petal)
            Text("Nothing scheduled")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkMuted)
            Text("Drag tasks here to schedule them")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkMuted.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Helpers

    private func daysInMonth() -> [Date?] {
        let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstOfMonth = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth)
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let startDay = settings.calendarStartDay
        let leadingBlanks = (firstWeekday - startDay + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in range {
            var dc = comps
            dc.day = day
            days.append(calendar.date(from: dc))
        }
        return days
    }

    private func requestCalendarAccessIfNeeded() {
        guard !CalendarService.shared.hasAccess else { return }
        Task {
            _ = await CalendarService.shared.requestAccess()
            loadCalendarEvents()
        }
    }

    private func loadCalendarEvents() {
        guard CalendarService.shared.hasAccess else { return }
        calendarEvents = CalendarService.shared.eventsGroupedByDay(for: displayedMonth)
    }
}
