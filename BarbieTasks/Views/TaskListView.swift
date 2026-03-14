import SwiftUI

struct TaskListView: View {
    @Environment(Store.self) private var store
    @Environment(AppSettings.self) private var settings
    @State private var quickAddText = ""
    @State private var quickAddDueDate: Date?
    @State private var quickAddPriority: BarbieTask.Priority = .none
    @State private var showQuickDatePicker = false
    @FocusState private var isQuickAddFocused: Bool

    var body: some View {
        let tasks = store.currentViewTasks

        VStack(spacing: 0) {
            header(taskCount: tasks.count)
            sortBar
            if store.isEditableView { quickAddRow }

            inlineCelebrations

            ScrollView {
                LazyVStack(spacing: 2) {
                    if tasks.isEmpty {
                        emptyState
                    } else if case .smartList(.upcoming) = store.selectedView {
                        upcomingGrouped(tasks)
                    } else {
                        ForEach(tasks) { task in
                            TaskRowView(task: task)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.92).combined(with: .opacity),
                                    removal: .scale(scale: 0.95).combined(with: .opacity).combined(with: .offset(x: 20))
                                ))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 60)
                .animation(.smooth(duration: 0.55), value: tasks.count)
            }
        }
        .background(Color.blush)
        .onChange(of: store.focusQuickAdd) {
            if store.focusQuickAdd {
                isQuickAddFocused = true
                store.focusQuickAdd = false
            }
        }
    }

    // MARK: - Header

    private func header(taskCount: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    headerIcon
                    Text(store.currentViewLabel)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkPrimary)
                }
                let remaining = store.currentViewTasks.filter { !$0.isDone }.count
                if taskCount > 0 {
                    Text("\(remaining) remaining")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkMuted)
                }
            }
            Spacer()

            // Progress ring
            if taskCount > 0 {
                progressRing
            }

            Button {
                withAnimation(.smooth(duration: 0.4)) { store.viewMode = .kanban }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "rectangle.split.3x1")
                        .font(.system(size: 11, weight: .bold))
                    Text("Kanban")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Color.barbiePink)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.blushMid, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    // MARK: - Sort Bar

    private var sortBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(SortOption.allCases) { opt in
                    Button {
                        withAnimation(.smooth(duration: 0.35)) { store.sortBy = opt; store.save() }
                    } label: {
                        Text(opt.label)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(store.sortBy == opt ? Color.barbiePink : Color.blush, in: Capsule())
                            .foregroundStyle(store.sortBy == opt ? .white : Color.inkSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Sort by \(opt.label)")
                    .accessibilityAddTraits(store.sortBy == opt ? .isSelected : [])
                }

                Spacer()

                if store.isEditableView {
                    Button {
                        withAnimation(.smooth(duration: 0.35)) { store.showCompleted.toggle(); store.save() }
                    } label: {
                        HStack(spacing: 4) {
                            if store.showCompleted { Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)) }
                            Text("Done")
                        }
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(store.showCompleted ? Color.barbiePink : Color.blush, in: Capsule())
                        .foregroundStyle(store.showCompleted ? .white : Color.inkSecondary)
                    }
                    .buttonStyle(.plain)
                }

                if case .smartList(.trash) = store.selectedView, store.count(for: .smartList(.trash)) > 0 {
                    Button { store.emptyTrash() } label: {
                        Text("Empty Trash")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color(hex: "#F5E0E0"), in: Capsule())
                            .foregroundStyle(Color(hex: "#C25050"))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Quick Add (with inline due date + priority)

    private var quickAddRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                BarbieIcon.QuickAdd(size: 20)
                    .accessibilityHidden(true)

                TextField("Add a task...", text: $quickAddText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .focused($isQuickAddFocused)
                    .onSubmit { submitQuickAdd() }
                    .onExitCommand { resetQuickAdd() }

                if !quickAddText.isEmpty {
                    Button { submitQuickAdd() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.barbiePink)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blush.opacity(0.5))

            // Inline toolbar: due date + priority (visible when focused or typing)
            if isQuickAddFocused || !quickAddText.isEmpty {
                quickAddToolbar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.smooth(duration: 0.25), value: isQuickAddFocused)
        .animation(.smooth(duration: 0.25), value: quickAddText.isEmpty)
    }

    private var quickAddToolbar: some View {
        HStack(spacing: 6) {
            // Due date quick picks
            quickDateButton(label: "Today", date: Calendar.current.startOfDay(for: Date()))
            quickDateButton(label: "Tomorrow", date: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!)
            quickDateButton(label: "Next Week", date: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Calendar.current.startOfDay(for: Date()))!)

            // Custom date picker
            Button {
                showQuickDatePicker.toggle()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 9, weight: .semibold))
                    if let d = quickAddDueDate, !isQuickDate(d) {
                        Text(d.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                }
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(quickAddDueDate != nil && !isQuickDate(quickAddDueDate!) ? Color.barbiePink : Color.inkMuted)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(
                    quickAddDueDate != nil && !isQuickDate(quickAddDueDate!)
                    ? Color.barbiePink.opacity(0.1)
                    : Color.blushMid,
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showQuickDatePicker) {
                DatePicker("", selection: Binding(
                    get: { quickAddDueDate ?? Date() },
                    set: { quickAddDueDate = $0; showQuickDatePicker = false }
                ), displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .frame(width: 280, height: 300)
                .padding(8)
            }

            if quickAddDueDate != nil {
                Button {
                    quickAddDueDate = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.inkMuted)
                }
                .buttonStyle(.plain)
            }

            // Divider
            Rectangle()
                .fill(Color.petal)
                .frame(width: 1, height: 14)
                .padding(.horizontal, 2)

            // Priority buttons
            ForEach(BarbieTask.Priority.allCases) { p in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        quickAddPriority = quickAddPriority == p ? .none : p
                    }
                } label: {
                    priorityLabel(p)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Natural language preview
            let parsed = NaturalDateParser.parse(quickAddText)
            if let proj = parsed.projectName {
                Text("#\(proj)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkSecondary)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.blushMid, in: Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .background(Color.blush.opacity(0.3))
    }

    private func quickDateButton(label: String, date: Date) -> some View {
        let isActive = quickAddDueDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                quickAddDueDate = isActive ? nil : date
            }
        } label: {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(isActive ? .white : Color.inkSecondary)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(isActive ? Color.barbiePink : Color.blushMid, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func priorityLabel(_ p: BarbieTask.Priority) -> some View {
        let isActive = quickAddPriority == p
        let color: Color = {
            switch p {
            case .high: return .priHigh
            case .medium: return .priMed
            case .low: return .priLow
            case .none: return .inkMuted
            }
        }()
        let label: String = {
            switch p {
            case .high: return "High"
            case .medium: return "Med"
            case .low: return "Low"
            case .none: return "None"
            }
        }()

        return HStack(spacing: 3) {
            Image(systemName: p == .none ? "minus" : p.symbol)
                .font(.system(size: 8, weight: .bold))
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
        }
        .foregroundStyle(isActive ? .white : color)
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(isActive ? color : color.opacity(0.08), in: Capsule())
        .overlay(
            Capsule().strokeBorder(isActive ? Color.clear : color.opacity(0.2), lineWidth: 0.5)
        )
    }

    private func isQuickDate(_ date: Date) -> Bool {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
        let nextWeek = cal.date(byAdding: .weekOfYear, value: 1, to: today)!
        return cal.isDate(date, inSameDayAs: today)
            || cal.isDate(date, inSameDayAs: tomorrow)
            || cal.isDate(date, inSameDayAs: nextWeek)
    }

    private func resetQuickAdd() {
        quickAddText = ""
        quickAddDueDate = nil
        quickAddPriority = .none
        showQuickDatePicker = false
        isQuickAddFocused = false
    }

    // MARK: - Upcoming Grouped

    @ViewBuilder
    private func upcomingGrouped(_ tasks: [BarbieTask]) -> some View {
        let grouped = Dictionary(grouping: tasks) { task -> String in
            guard let d = task.dueDate else { return "No Date" }
            return d.formatted(.dateTime.year().month().day())
        }
        let sortedKeys = grouped.keys.sorted()

        ForEach(sortedKeys, id: \.self) { key in
            let groupTasks = grouped[key]!
            let firstDate = groupTasks.first?.dueDate

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if let d = firstDate {
                        Text(d.formatted(.dateTime.weekday(.wide)))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.inkPrimary)
                        Text("\u{2022}").foregroundStyle(Color.petal)
                        Text(d.formatted(.dateTime.month(.wide).day()))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.inkSecondary)
                    } else {
                        Text("No Date")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.inkMuted)
                    }
                }
                .padding(.top, 14).padding(.bottom, 4).padding(.horizontal, 4)

                ForEach(groupTasks) { task in
                    TaskRowView(task: task)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        let (icon, title, subtitle) = emptyContent
        return VStack(spacing: 10) {
            BarbieIcon.EmptyState(systemName: icon, size: 36)
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkSecondary)
            Text(subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 240)

            if store.isEditableView {
                Button {
                    store.focusQuickAdd = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add Task")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.barbiePink, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity).padding(.top, 80)
    }

    @ViewBuilder
    private var headerIcon: some View {
        switch store.selectedView {
        case .smartList(.inbox):    BarbieIcon.Inbox(size: 20)
        case .smartList(.today):    BarbieIcon.Today(size: 20)
        case .smartList(.upcoming): BarbieIcon.Upcoming(size: 20)
        case .smartList(.calendar): BarbieIcon.CalendarIcon(size: 20)
        case .smartList(.anytime):  BarbieIcon.AllTasks(size: 20)
        case .smartList(.logbook):  BarbieIcon.Logbook(size: 20)
        case .smartList(.trash):    BarbieIcon.Trash(size: 20)
        case .project:              BarbieIcon.Project(size: 20)
        case .tag:                  BarbieIcon.Tag(size: 20)
        case .savedFilter:          Image(systemName: "line.3.horizontal.decrease.circle").font(.system(size: 20)).foregroundStyle(Color.barbiePink)
        case .stats:                BarbieIcon.Stats(size: 20)
        }
    }

    private func submitQuickAdd() {
        guard !quickAddText.isEmpty else { return }
        withAnimation(.smooth(duration: 0.45)) {
            store.addTask(
                title: quickAddText,
                explicitDueDate: quickAddDueDate,
                explicitPriority: quickAddPriority != .none ? quickAddPriority : nil
            )
            resetQuickAdd()
        }
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        ProgressRingView()
    }

    // MARK: - Celebration Colors

    private static let classicRainbow: [Color] = [
        Color(hex: "#D86878"), // pastel red
        Color(hex: "#E89850"), // pastel orange
        Color(hex: "#D8B840"), // pastel amber
        Color(hex: "#58B878"), // pastel green
        Color(hex: "#58A0D0"), // pastel blue
        Color(hex: "#7868B8"), // pastel indigo
        Color(hex: "#A068C0"), // pastel violet
    ]

    private func celebrationColor(for index: Int) -> some ShapeStyle {
        if ThemeManager.shared.current == .classic {
            let color = Self.classicRainbow[index % Self.classicRainbow.count]
            return AnyShapeStyle(color)
        } else {
            return AnyShapeStyle(Color.barbieDeep)
        }
    }

    // MARK: - Inline Celebrations

    @ViewBuilder
    private var inlineCelebrations: some View {
        if !store.activeCelebrations.isEmpty {
            VStack(spacing: 4) {
                ForEach(Array(store.activeCelebrations.enumerated()), id: \.element.id) { index, quote in
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.barbiePink)
                            .symbolEffect(.bounce, value: quote.id)
                        Text(quote.text)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(celebrationColor(for: index))
                            .lineLimit(2)
                            .contentTransition(.interpolate)
                        Spacer(minLength: 0)
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.barbiePink.opacity(0.7))
                            .symbolEffect(.bounce, value: quote.id)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blushMid)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [Color.barbiePink.opacity(0.3), Color.barbieRose.opacity(0.15)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .transition(
                        .asymmetric(
                            insertion: .push(from: .top).combined(with: .opacity),
                            removal: .push(from: .bottom).combined(with: .opacity)
                        )
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .animation(.smooth(duration: 0.35), value: store.activeCelebrations.map(\.id))
        }
    }

    private var emptyContent: (String, String, String) {
        switch store.selectedView {
        case .smartList(.inbox):    return ("tray",              "All Clear",       "Add a task to get started.")
        case .smartList(.today):    return ("sun.max",           "Free Day",        "Nothing due today.")
        case .smartList(.upcoming): return ("calendar.badge.clock", "All Clear",    "No upcoming deadlines.")
        case .smartList(.anytime):  return ("list.bullet",       "Fresh Start",     "Add something fabulous.")
        case .smartList(.logbook):  return ("book.closed",       "No History Yet",  "Completed tasks appear here.")
        case .smartList(.trash):    return ("trash",             "Squeaky Clean",   "Trash is empty.")
        case .project:              return ("folder",            "Empty Project",   "Add your first task.")
        case .tag:                  return ("tag",               "No Tagged Tasks", "Tag a task to see it here.")
        case .savedFilter:          return ("line.3.horizontal.decrease.circle", "No Matches", "No tasks match this filter.")
        default:                    return ("circle.dashed",     "Nothing Here",    "")
        }
    }
}
