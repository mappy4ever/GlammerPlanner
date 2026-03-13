import SwiftUI

struct ContentView: View {
    @Environment(Store.self) private var store
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var store = store

        ZStack {
            NavigationSplitView(columnVisibility: .constant(.all)) {
                SidebarView()
                    .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 280)
            } content: {
                Group {
                    switch store.selectedView {
                    case .smartList(.calendar):
                        CalendarView()
                            .transition(.opacity)
                    case .stats:
                        StatsView()
                            .transition(.opacity)
                    default:
                        if store.viewMode == .kanban {
                            KanbanView()
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        } else {
                            TaskListView()
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: store.selectedView)
                .animation(.easeInOut(duration: 0.25), value: store.viewMode)
                .navigationSplitViewColumnWidth(min: 300, ideal: 420, max: .infinity)
            } detail: {
                if let task = store.selectedTask {
                    DetailView(task: task)
                } else {
                    DetailPlaceholder()
                }
            }
            .searchable(text: $store.searchText, placement: .toolbar, prompt: "Search tasks...")
            .tint(.barbiePink)
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    // Pomodoro mini view
                    PomodoroMiniViewWithSettings()
                }
            }

            // Celebration overlay
            if store.celebrationQuote != nil {
                CelebrationOverlay()
            }

            // Confetti
            if store.showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }

            // Command palette
            if store.showCommandPalette {
                CommandPalette()
            }

            // Bulk action bar
            if store.selectedTaskIds.count > 1 {
                VStack {
                    Spacer()
                    BulkActionBar()
                }
            }
        }
        .overlay(alignment: .bottom) {
            ToastView()
        }
        .sheet(isPresented: $store.showNewProject) {
            NewProjectView()
        }
        .sheet(isPresented: $store.showNewTag) {
            TagEditor()
        }
        .sheet(isPresented: $store.showTemplateManager) {
            TemplateManagerView()
        }
        .sheet(isPresented: $store.showNewFilter) {
            FilterEditorView()
        }
        .sheet(item: $store.editingFilter) { filter in
            FilterEditorView(existingFilter: filter)
        }
        .sheet(item: Binding(
            get: { store.saveAsTemplateTaskId.flatMap { id in store.tasks.first { $0.id == id } } },
            set: { _ in store.saveAsTemplateTaskId = nil }
        )) { task in
            SaveAsTemplateSheet(task: task)
        }
        .onKeyPress(.escape) {
            if store.showCommandPalette {
                store.showCommandPalette = false
                return .handled
            }
            if store.selectedTaskId != nil {
                store.selectedTaskId = nil
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.downArrow) {
            if !store.showCommandPalette {
                store.selectNextTask()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.upArrow) {
            if !store.showCommandPalette {
                store.selectPreviousTask()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.space) {
            if !store.showCommandPalette, let id = store.selectedTaskId {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    store.toggleTask(id)
                }
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.delete) {
            if let id = store.selectedTaskId {
                store.trashTask(id)
                return .handled
            }
            return .ignored
        }
        .onChange(of: store.selectedView) {
            NSApp.mainWindow?.title = "\(store.currentViewLabel) \u{2014} Glam Plan"
        }
        .onAppear {
            NSApp.mainWindow?.title = "\(store.currentViewLabel) \u{2014} Glam Plan"
        }
    }
}

// MARK: - Detail Placeholder

private struct DetailPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            BarbieIcon.EmptyState(systemName: "checkmark.circle", size: 36)
            Text("Select a task")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blush.opacity(0.3))
    }
}

// MARK: - Toast

private struct ToastView: View {
    @Environment(Store.self) private var store
    @State private var toastScale: CGFloat = 0.9

    var body: some View {
        if let message = store.toastMessage {
            HStack(spacing: 12) {
                Text(message)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Button("Undo") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        store.performUndo()
                    }
                }
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.gold)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.inkPrimary, in: Capsule())
            .shadow(color: Color.barbiePink.opacity(0.12), radius: 16, y: 6)
            .scaleEffect(toastScale)
            .padding(.bottom, 20)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(message)
            .accessibilityAddTraits(.isStaticText)
            .transition(
                .asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.85)),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                )
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    store.dismissToast()
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    toastScale = 1.0
                }
            }
        }
    }
}
