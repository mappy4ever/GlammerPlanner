import SwiftUI

struct TaskListView: View {
    @Environment(Store.self) private var store
    @State private var quickAddText = ""
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
                let total = store.currentViewTasks.count
                let done = store.currentViewTasks.filter(\.isDone).count
                let pct = total > 0 ? Double(done) / Double(total) : 0
                ZStack {
                    Circle().stroke(Color.petalLight, lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: pct)
                        .stroke(Color.barbiePink, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.smooth(duration: 0.4), value: pct)
                    Text("\(Int(pct * 100))%")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkSecondary)
                }
                .frame(width: 36, height: 36)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Progress")
                .accessibilityValue("\(done) of \(total) tasks completed, \(Int(pct * 100)) percent")
            }
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

                // List / Kanban toggle
                HStack(spacing: 2) {
                    Button {
                        withAnimation(.smooth(duration: 0.35)) { store.viewMode = .list }
                    } label: {
                        Group {
                            if store.viewMode == .list {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                BarbieIcon.AllTasks(size: 11)
                            }
                        }
                        .padding(5)
                        .background(store.viewMode == .list ? Color.barbiePink : Color.clear, in: RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("List view")
                    .accessibilityAddTraits(store.viewMode == .list ? .isSelected : [])

                    Button {
                        withAnimation(.smooth(duration: 0.35)) { store.viewMode = .kanban }
                    } label: {
                        Group {
                            if store.viewMode == .kanban {
                                Image(systemName: "rectangle.split.3x1")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                BarbieIcon.Kanban(size: 11)
                            }
                        }
                        .padding(5)
                        .background(store.viewMode == .kanban ? Color.barbiePink : Color.clear, in: RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Kanban view")
                    .accessibilityAddTraits(store.viewMode == .kanban ? .isSelected : [])
                }
                .background(Color.blushMid, in: RoundedRectangle(cornerRadius: 6))

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

    // MARK: - Quick Add (with natural language hint)

    private var quickAddRow: some View {
        VStack(spacing: 2) {
            HStack(spacing: 8) {
                BarbieIcon.QuickAdd(size: 20)
                    .accessibilityHidden(true)

                TextField("Add a task...", text: $quickAddText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .focused($isQuickAddFocused)
                    .onSubmit { submitQuickAdd() }
                    .onExitCommand {
                        quickAddText = ""
                        isQuickAddFocused = false
                    }

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

            // Show parsed preview if user is typing date keywords
            if !quickAddText.isEmpty {
                let parsed = NaturalDateParser.parse(quickAddText)
                if parsed.dueDate != nil || parsed.priority > 0 || parsed.projectName != nil {
                    HStack(spacing: 8) {
                        if let date = parsed.dueDate {
                            HStack(spacing: 3) {
                                Image(systemName: "calendar").font(.system(size: 9))
                                Text(datePreviewText(date))
                            }
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.barbiePink)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.blushMid, in: Capsule())
                        }
                        if parsed.priority > 0 {
                            let label = ["","Low","Med","High"][parsed.priority]
                            Text(label)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.barbiePink)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.blushMid, in: Capsule())
                        }
                        if let proj = parsed.projectName {
                            Text("#\(proj)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.inkSecondary)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.blushMid, in: Capsule())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 48)
                    .padding(.bottom, 4)
                    .transition(.opacity)
                }
            }
        }
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
            store.addTask(title: quickAddText)
            quickAddText = ""
        }
    }

    private func datePreviewText(_ date: Date) -> String {
        let cal = Calendar.current
        let hasTime = !cal.isDate(date, equalTo: cal.startOfDay(for: date), toGranularity: .minute)
        let dateStr = date.formatted(.dateTime.month(.abbreviated).day())
        if hasTime {
            let timeStr = date.formatted(.dateTime.hour().minute())
            return "\(dateStr) \(timeStr)"
        }
        return dateStr
    }

    // MARK: - Inline Celebrations

    @ViewBuilder
    private var inlineCelebrations: some View {
        if !store.activeCelebrations.isEmpty {
            VStack(spacing: 4) {
                ForEach(store.activeCelebrations) { quote in
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.barbiePink)
                            .symbolEffect(.bounce, value: quote.id)
                        Text(quote.text)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.barbieDeep, Color.barbiePink, Color.barbieRose],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .lineLimit(2)
                        Spacer(minLength: 0)
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.barbiePink.opacity(0.5))
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
        case .smartList(.inbox):    return ("tray",              "Slay List Zero",  "Add a task to get started.")
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
