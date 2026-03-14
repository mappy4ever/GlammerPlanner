import SwiftUI

struct SidebarView: View {
    @Environment(Store.self) private var store
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var store = store

        List(selection: $store.selectedView) {
            // Logo
            HStack {
                Spacer()
                VStack(spacing: 1) {
                    Text("Slay List")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.barbieDeep, .barbiePink, .barbieRose],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                    Text(AppThemeId(rawValue: settings.appTheme)?.tagline ?? "Get it done, gorgeously")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkMuted)
                }
                Spacer()
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .padding(.vertical, 4)

            // Smart lists
            Section {
                ForEach(SmartList.primary) { list in
                    let count = store.count(for: .smartList(list))
                    let active = store.selectedView == .smartList(list)
                    NavigationLink(value: ViewSelection.smartList(list)) {
                        Label {
                            HStack {
                                Text(list.label)
                                Spacer()
                                if count > 0 {
                                    countBadge(count, active: active)
                                        .accessibilityHidden(true)
                                }
                            }
                        } icon: {
                            smartListIcon(list, active: active)
                                .accessibilityHidden(true)
                        }
                    }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .accessibilityLabel(count > 0 ? "\(list.label), \(count) tasks" : list.label)
                }

                // Stats
                NavigationLink(value: ViewSelection.stats) {
                    Label {
                        Text("Statistics")
                    } icon: {
                        Group {
                            if store.selectedView == .stats {
                                Image(systemName: "chart.bar")
                                    .foregroundStyle(.white)
                            } else {
                                BarbieIcon.Stats(size: 14)
                            }
                        }
                        .accessibilityHidden(true)
                    }
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))

                // Routines
                Button { store.showRoutineManager = true } label: {
                    Label {
                        HStack {
                            Text("Routines")
                            Spacer()
                            if !store.todayRoutines.isEmpty {
                                Text("\(store.todayRoutines.count)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.inkMuted)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Color.petal.opacity(0.5), in: Capsule())
                            }
                        }
                    } icon: {
                        BarbieIcon.Routines(size: 14)
                    }
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .buttonStyle(.plain)
            }

            // Projects — simple flat list
            if !store.sortedProjects.isEmpty {
                Section("Projects") {
                    ForEach(store.sortedProjects) { project in
                        let count = store.count(for: .project(project.id))
                        NavigationLink(value: ViewSelection.project(project.id)) {
                            HStack(spacing: 8) {
                                BarbieIcon.Project(color: project.color, size: 14)
                                    .accessibilityHidden(true)
                                Text(project.title).lineLimit(1)
                                    .help(project.title)
                                Spacer()
                                if count > 0 {
                                    countBadge(count, active: store.selectedView == .project(project.id))
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .accessibilityLabel(count > 0 ? "\(project.title), \(count) tasks" : project.title)
                        .contextMenu {
                            Button("Delete Project", role: .destructive) {
                                store.deleteProject(project.id)
                            }
                        }
                    }
                }
            }

            // Tags — simple flat list
            if !store.sortedTags.isEmpty {
                Section("Tags") {
                    ForEach(store.sortedTags) { tag in
                        let count = store.count(for: .tag(tag.id))
                        NavigationLink(value: ViewSelection.tag(tag.id)) {
                            HStack(spacing: 8) {
                                BarbieIcon.Tag(color: tag.color, size: 14)
                                    .accessibilityHidden(true)
                                Text(tag.name).lineLimit(1)
                                    .help(tag.name)
                                Spacer()
                                if count > 0 {
                                    countBadge(count, active: store.selectedView == .tag(tag.id))
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .accessibilityLabel(count > 0 ? "\(tag.name), \(count) tasks" : tag.name)
                        .contextMenu {
                            Button("Delete Tag", role: .destructive) {
                                store.deleteTag(tag.id)
                            }
                        }
                    }
                }
            }

            // Filters
            if !store.savedFilters.isEmpty {
                Section("Filters") {
                    ForEach(store.savedFilters) { filter in
                        let count = store.count(for: .savedFilter(filter.id))
                        NavigationLink(value: ViewSelection.savedFilter(filter.id)) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(filter.color)
                                    .frame(width: 10, height: 10)
                                    .accessibilityHidden(true)
                                Text(filter.name).lineLimit(1)
                                Spacer()
                                if count > 0 {
                                    countBadge(count, active: store.selectedView == .savedFilter(filter.id))
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .accessibilityLabel(count > 0 ? "\(filter.name), \(count) tasks" : filter.name)
                        .contextMenu {
                            Button("Edit Filter") {
                                store.editingFilter = filter
                            }
                            Divider()
                            Button("Delete Filter", role: .destructive) {
                                store.deleteSavedFilter(filter.id)
                            }
                        }
                    }
                }
            }

            // Bottom lists
            Section {
                ForEach(SmartList.secondary) { list in
                    let count = store.count(for: .smartList(list))
                    let active = store.selectedView == .smartList(list)
                    NavigationLink(value: ViewSelection.smartList(list)) {
                        Label {
                            HStack {
                                Text(list.label)
                                Spacer()
                                if count > 0 {
                                    countBadge(count, active: active)
                                        .accessibilityHidden(true)
                                }
                            }
                        } icon: {
                            smartListIcon(list, active: active)
                                .accessibilityHidden(true)
                        }
                    }
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .accessibilityLabel(count > 0 ? "\(list.label), \(count) tasks" : list.label)
                }
            }

            // Overdue alert
            if store.overdueCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "#C25050"))
                    Text("\(store.overdueCount) overdue")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#C25050"))
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#FBEAEA").opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .onTapGesture {
                    store.selectedView = .smartList(.today)
                }
            }

            // Footer
            Section {
                // New items
                HStack(spacing: 16) {
                    Button { store.showNewProject = true } label: {
                        Label("Project", systemImage: "plus")
                    }
                    Button { store.showNewTag = true } label: {
                        Label("Tag", systemImage: "plus")
                    }
                    Button { store.showNewFilter = true } label: {
                        Label("Filter", systemImage: "plus")
                    }
                }
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.inkMuted)
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                // Daily goal mini ring + streak
                dailyGoalFooter
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Color.blush)
        .onChange(of: store.selectedView) {
            store.selectedTaskIds = []
        }
    }

    private var dailyGoalFooter: some View {
        let goal = store.profile.dailyGoal
        let done = store.completedToday
        let progress = store.dailyGoalProgress

        return HStack(spacing: 10) {
            // Mini progress ring
            ZStack {
                Circle()
                    .stroke(Color.petal, lineWidth: 3)
                    .frame(width: 28, height: 28)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: done >= goal ? [.barbieRose, .barbiePink] : [.barbiePink, .barbieDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)

                Text("\(done)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(done >= goal ? Color.barbiePink : Color.inkPrimary)
            }

            VStack(alignment: .leading, spacing: 1) {
                if done >= goal {
                    Text("Goal reached!")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.barbiePink)
                } else {
                    Text("\(done)/\(goal) today")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkSecondary)
                }
            }

            Spacer()

            // Streak flame
            if store.currentStreak > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.barbiePink, Color(hex: "#FF6B6B")],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                    Text("\(store.currentStreak)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkPrimary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func smartListIcon(_ list: SmartList, active: Bool) -> some View {
        if active {
            Image(systemName: list.icon)
                .foregroundStyle(.white)
        } else {
            switch list {
            case .inbox:    BarbieIcon.Inbox(size: 15)
            case .today:    BarbieIcon.Today(size: 15)
            case .upcoming: BarbieIcon.Upcoming(size: 15)
            case .calendar: BarbieIcon.CalendarIcon(size: 15)
            case .anytime:  BarbieIcon.AllTasks(size: 15)
            case .logbook:  BarbieIcon.Logbook(size: 15)
            case .trash:    BarbieIcon.Trash(size: 15)
            }
        }
    }

    private func countBadge(_ count: Int, active: Bool) -> some View {
        Text("\(count)")
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(active ? .white.opacity(0.8) : Color.inkMuted)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(
                active ? Color.white.opacity(0.2) : Color.petal.opacity(0.5),
                in: Capsule()
            )
    }
}
