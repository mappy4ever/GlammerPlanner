import SwiftUI

struct CommandPalette: View {
    @Environment(Store.self) private var store
    @Environment(AppSettings.self) private var settings
    @State private var query = ""
    @State private var selectedIndex = 0
    @State private var appeared = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Palette card
            VStack(spacing: 0) {
                searchField
                Divider().background(Color.petal)
                resultsList
            }
            .frame(width: 520)
            .frame(maxHeight: 420)
            .background(Color.blush, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.petal, lineWidth: 1)
            )
            .shadow(color: Color.barbiePink.opacity(0.12), radius: 30, y: 10)
            .scaleEffect(appeared ? 1.0 : 0.92)
            .opacity(appeared ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                appeared = true
            }
            isSearchFocused = true
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(.return) {
            executeSelected()
            return .handled
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 10) {
            BarbieIcon.Search(size: 16)

            TextField("Search tasks, projects, actions...", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkPrimary)
                .focused($isSearchFocused)
                .onChange(of: query) { _, _ in
                    selectedIndex = 0
                }

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.inkMuted)
                }
                .buttonStyle(.plain)
            }

            // Shortcut badge
            Text("\u{2318}K")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkMuted)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.blushMid, in: RoundedRectangle(cornerRadius: 5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Results List

    private var resultsList: some View {
        let grouped = groupedResults

        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if grouped.isEmpty {
                        emptyState
                    } else {
                        var runningIndex = 0
                        ForEach(grouped, id: \.title) { group in
                            let groupStart = runningIndex

                            Section {
                                ForEach(Array(group.items.enumerated()), id: \.element.id) { offset, item in
                                    let globalIdx = groupStart + offset
                                    resultRow(item: item, index: globalIdx)
                                        .id(globalIdx)
                                }
                            } header: {
                                sectionHeader(group.title)
                            }

                            let _ = (runningIndex = groupStart + group.items.count)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            .onChange(of: selectedIndex) { _, newVal in
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo(newVal, anchor: .center)
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(Color.inkMuted)
            .textCase(.uppercase)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 4)
    }

    private func resultRow(item: PaletteItem, index: Int) -> some View {
        let isSelected = index == selectedIndex

        return Button {
            execute(item)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : Color.barbiePink)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? .white : Color.inkPrimary)
                        .lineLimit(1)

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(isSelected ? .white.opacity(0.7) : Color.inkMuted)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if let shortcut = item.shortcut {
                    Text(shortcut)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? .white.opacity(0.7) : Color.inkMuted)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            isSelected
                                ? Color.white.opacity(0.15)
                                : Color.blushMid,
                            in: RoundedRectangle(cornerRadius: 4)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? Color.barbiePink
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
        .onHover { hovering in
            if hovering { selectedIndex = index }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            BarbieIcon.EmptyState(systemName: "sparkle.magnifyingglass", size: 28)
            Text("No results found")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Data

    private var groupedResults: [PaletteGroup] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()

        var groups: [PaletteGroup] = []

        // Actions
        let filteredActions = builtInActions.filter { item in
            q.isEmpty || fuzzyMatch(query: q, target: item.title.lowercased())
        }
        if !filteredActions.isEmpty {
            groups.append(PaletteGroup(title: "Actions", items: Array(filteredActions.prefix(6))))
        }

        // Tasks
        if !q.isEmpty {
            let matchingTasks = store.incompleteTasks.filter { task in
                fuzzyMatch(query: q, target: task.title.lowercased())
            }
            let taskItems = matchingTasks.prefix(8).map { task in
                let projectName = store.project(for: task)?.title
                return PaletteItem(
                    id: "task-\(task.id.uuidString)",
                    title: task.title,
                    subtitle: projectName,
                    icon: task.isDone ? "checkmark.circle.fill" : "circle",
                    action: .selectTask(task.id)
                )
            }
            if !taskItems.isEmpty {
                groups.append(PaletteGroup(title: "Tasks", items: Array(taskItems)))
            }
        }

        // Projects
        let matchingProjects = store.projects.filter { proj in
            q.isEmpty ? false : fuzzyMatch(query: q, target: proj.title.lowercased())
        }
        if !matchingProjects.isEmpty {
            let projItems = matchingProjects.prefix(5).map { proj in
                PaletteItem(
                    id: "project-\(proj.id.uuidString)",
                    title: proj.title,
                    subtitle: "\(store.count(for: .project(proj.id))) tasks",
                    icon: "folder.fill",
                    action: .switchView(.project(proj.id))
                )
            }
            groups.append(PaletteGroup(title: "Projects", items: Array(projItems)))
        }

        // Tags
        let matchingTags = store.tags.filter { tag in
            q.isEmpty ? false : fuzzyMatch(query: q, target: tag.name.lowercased())
        }
        if !matchingTags.isEmpty {
            let tagItems = matchingTags.prefix(5).map { tag in
                PaletteItem(
                    id: "tag-\(tag.id.uuidString)",
                    title: tag.name,
                    subtitle: nil,
                    icon: "tag.fill",
                    action: .switchView(.tag(tag.id))
                )
            }
            groups.append(PaletteGroup(title: "Tags", items: Array(tagItems)))
        }

        // Templates
        let matchingTemplates = store.templates.filter { t in
            q.isEmpty ? false : fuzzyMatch(query: q, target: t.name.lowercased())
        }
        if !matchingTemplates.isEmpty {
            let templateItems = matchingTemplates.prefix(5).map { t in
                PaletteItem(
                    id: "template-\(t.id.uuidString)",
                    title: t.name,
                    subtitle: "Create from template",
                    icon: "doc.on.doc.fill",
                    action: .createFromTemplate(t.id)
                )
            }
            groups.append(PaletteGroup(title: "Templates", items: Array(templateItems)))
        }

        return groups
    }

    private var builtInActions: [PaletteItem] {
        [
            PaletteItem(
                id: "action-new-task", title: "New Task", subtitle: nil,
                icon: "plus.circle.fill", shortcut: "\u{2318}N",
                action: .newTask
            ),
            PaletteItem(
                id: "action-new-project", title: "New Project", subtitle: nil,
                icon: "folder.badge.plus", action: .newProject
            ),
            PaletteItem(
                id: "action-new-tag", title: "New Tag", subtitle: nil,
                icon: "tag.fill", action: .newTag
            ),
            PaletteItem(
                id: "action-inbox", title: "Switch to Inbox", subtitle: nil,
                icon: "tray", action: .switchView(.smartList(.inbox))
            ),
            PaletteItem(
                id: "action-today", title: "Switch to Today", subtitle: nil,
                icon: "star", action: .switchView(.smartList(.today))
            ),
            PaletteItem(
                id: "action-upcoming", title: "Switch to Upcoming", subtitle: nil,
                icon: "calendar.badge.clock", action: .switchView(.smartList(.upcoming))
            ),
            PaletteItem(
                id: "action-all", title: "Switch to All Tasks", subtitle: nil,
                icon: "list.bullet", action: .switchView(.smartList(.anytime))
            ),
            PaletteItem(
                id: "action-logbook", title: "Switch to Logbook", subtitle: nil,
                icon: "book.closed", action: .switchView(.smartList(.logbook))
            ),
            PaletteItem(
                id: "action-dark-mode", title: "Toggle Dark Mode", subtitle: currentAppearanceLabel,
                icon: "moon.fill", action: .toggleDarkMode
            ),
            PaletteItem(
                id: "action-settings", title: "Open Settings", subtitle: nil,
                icon: "gearshape.fill", shortcut: "\u{2318},",
                action: .openSettings
            ),
            PaletteItem(
                id: "action-focus", title: "Start Focus Timer", subtitle: nil,
                icon: "timer", action: .startFocusTimer
            ),
            PaletteItem(
                id: "action-templates", title: "Manage Templates", subtitle: "\(store.templates.count) templates",
                icon: "doc.on.doc", shortcut: "\u{21E7}\u{2318}T",
                action: .openTemplates
            ),
            PaletteItem(
                id: "action-kanban", title: "Toggle Kanban View", subtitle: store.viewMode == .kanban ? "Currently: Board" : "Currently: List",
                icon: "rectangle.split.3x1", action: .toggleKanban
            ),
        ] + (store.selectedTaskId != nil ? [
            PaletteItem(
                id: "action-duplicate", title: "Duplicate Task", subtitle: store.selectedTask?.title,
                icon: "plus.square.on.square", shortcut: "\u{2318}D",
                action: .duplicateTask
            ),
        ] : [])
    }

    private var currentAppearanceLabel: String {
        switch settings.appearance {
        case "dark":  "Currently: Dark"
        case "light": "Currently: Light"
        default:      "Currently: System"
        }
    }

    private var flatResults: [PaletteItem] {
        groupedResults.flatMap(\.items)
    }

    // MARK: - Fuzzy Match

    /// Simple subsequence-based fuzzy match: every character of the query
    /// must appear in order within the target string.
    private func fuzzyMatch(query: String, target: String) -> Bool {
        var targetIndex = target.startIndex
        for char in query {
            guard let found = target[targetIndex...].firstIndex(of: char) else {
                return false
            }
            targetIndex = target.index(after: found)
        }
        return true
    }

    // MARK: - Navigation

    private func moveSelection(by delta: Int) {
        let items = flatResults
        guard !items.isEmpty else { return }
        selectedIndex = max(0, min(items.count - 1, selectedIndex + delta))
    }

    private func executeSelected() {
        let items = flatResults
        guard selectedIndex < items.count else { return }
        execute(items[selectedIndex])
    }

    private func execute(_ item: PaletteItem) {
        dismiss()

        switch item.action {
        case .selectTask(let id):
            store.selectedTaskId = id

        case .switchView(let view):
            store.selectedView = view

        case .newTask:
            store.focusQuickAdd = true

        case .newProject:
            store.showNewProject = true

        case .newTag:
            store.showNewTag = true

        case .toggleDarkMode:
            switch settings.appearance {
            case "dark":  settings.appearance = "light"
            case "light": settings.appearance = "system"
            default:      settings.appearance = "dark"
            }

        case .openSettings:
            if #available(macOS 14, *) {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } else {
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            }

        case .startFocusTimer:
            store.selectedView = .stats

        case .openTemplates:
            store.showTemplateManager = true

        case .toggleKanban:
            withAnimation(.easeOut(duration: 0.2)) {
                store.viewMode = store.viewMode == .kanban ? .list : .kanban
            }

        case .createFromTemplate(let id):
            store.createFromTemplate(id)

        case .duplicateTask:
            if let id = store.selectedTaskId {
                store.duplicateTask(id)
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.15)) {
            appeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            store.showCommandPalette = false
        }
    }
}

// MARK: - Models

private enum PaletteAction {
    case selectTask(UUID)
    case switchView(ViewSelection)
    case newTask
    case newProject
    case newTag
    case toggleDarkMode
    case openSettings
    case startFocusTimer
    case openTemplates
    case toggleKanban
    case createFromTemplate(UUID)
    case duplicateTask
}

private struct PaletteItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let icon: String
    var shortcut: String? = nil
    let action: PaletteAction
}

private struct PaletteGroup: Identifiable {
    let title: String
    let items: [PaletteItem]
    var id: String { title }
}
