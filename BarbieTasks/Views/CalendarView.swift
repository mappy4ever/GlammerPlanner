import SwiftUI
import EventKit

struct CalendarView: View {
    @Environment(Store.self) private var store
    @Environment(AppSettings.self) private var settings

    @State private var displayedMonth: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showCalendarEvents: Bool = true
    @State private var calendarEvents: [Date: [EKEvent]] = [:]
    @State private var monthTransitionDirection: Edge = .trailing
    @State private var monthId = UUID()
    @State private var dropTargetDate: Date?

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
            // Month navigation header
            monthHeader
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Weekday labels
            weekdayHeader
                .padding(.horizontal, 16)

            // Calendar grid
            calendarGrid
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .id(monthId)
                .transition(.asymmetric(
                    insertion: .move(edge: monthTransitionDirection).combined(with: .opacity),
                    removal: .move(edge: monthTransitionDirection == .trailing ? .leading : .trailing).combined(with: .opacity)
                ))

            Divider()
                .foregroundStyle(Color.petal)

            // Toggle for calendar events
            calendarToggle
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            Divider()
                .foregroundStyle(Color.petalLight)

            // Selected day content
            selectedDayContent
        }
        .background(Color.blush)
        .onAppear {
            requestCalendarAccessIfNeeded()
            loadCalendarEvents()
        }
        .onChange(of: displayedMonth) { _, _ in
            loadCalendarEvents()
        }
    }

    // MARK: - Month Header

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

            // Today button
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

    // MARK: - Weekday Header

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

    // MARK: - Calendar Grid

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

            // Indicator dots
            HStack(spacing: 2) {
                if totalCount > 0 {
                    // Show completion as mini bar
                    if totalCount <= 3 {
                        taskDots(for: dayTasks)
                    } else {
                        // Compact count badge for busy days
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

    // MARK: - Calendar Toggle

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

    // MARK: - Selected Day Content

    private var selectedDayContent: some View {
        let dayTasks = store.tasksForDay(selectedDate)
        let dayEvents = (calendarEvents[calendar.startOfDay(for: selectedDate)] ?? [])
            .sorted { $0.startDate < $1.startDate }

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Date label
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

                // Tasks section
                if !dayTasks.isEmpty {
                    sectionHeader(title: "Tasks", count: dayTasks.count)

                    ForEach(dayTasks) { task in
                        TaskRowView(task: task)
                            .draggable(task.id.uuidString)
                    }
                }

                // Calendar events section
                if showCalendarEvents && !dayEvents.isEmpty {
                    sectionHeader(title: "Calendar Events", count: dayEvents.count)

                    ForEach(dayEvents, id: \.eventIdentifier) { event in
                        calendarEventRow(event)
                    }
                }

                // Empty state
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
            // Calendar color dot
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
