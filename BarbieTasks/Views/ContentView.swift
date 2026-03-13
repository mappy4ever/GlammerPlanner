import SwiftUI

struct ContentView: View {
    @Environment(Store.self) private var store
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var store = store

        mainContent
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
                SaveAsTemplateSheet(taskId: task.id)
            }
            .onKeyPress(.escape) {
                if store.showCommandPalette {
                    store.showCommandPalette = false
                    return .handled
                }
                if store.selectedTaskIds.count > 1 {
                    store.selectedTaskIds.removeAll()
                    return .handled
                }
                if store.selectedTaskId != nil {
                    store.selectedTaskId = nil
                    return .handled
                }
                // Remove focus from any text field
                NSApp.keyWindow?.makeFirstResponder(nil)
                return .handled
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
                    withAnimation(.smooth(duration: 0.3)) {
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
                NSApp.mainWindow?.title = "\(store.currentViewLabel) \u{2014} Slay List"
            }
            .onAppear {
                NSApp.mainWindow?.title = "\(store.currentViewLabel) \u{2014} Slay List"
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        @Bindable var store = store

        ZStack {
            NavigationSplitView(columnVisibility: .constant(.all)) {
                SidebarView()
                    .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 280)
            } content: {
                contentColumn
                    .animation(.smooth(duration: 0.3), value: store.selectedView)
                    .animation(.smooth(duration: 0.3), value: store.viewMode)
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
                    Button {
                        withAnimation(.smooth(duration: 0.25)) { store.performUndo() }
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .disabled(!store.canUndo)
                    .help(store.undoActionName.map { "Undo \($0)" } ?? "Undo")

                    Button {
                        withAnimation(.smooth(duration: 0.25)) { store.performRedo() }
                    } label: {
                        Image(systemName: "arrow.uturn.forward")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .disabled(!store.canRedo)
                    .help(store.redoActionName.map { "Redo \($0)" } ?? "Redo")

                    PomodoroMiniViewWithSettings()
                }
            }

            overlayViews
        }
    }

    @ViewBuilder
    private var contentColumn: some View {
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
                    .transition(.blurReplace)
            } else {
                TaskListView()
                    .transition(.blurReplace)
            }
        }
    }

    @ViewBuilder
    private var overlayViews: some View {
        // Celebration banner — slides in at top, feels part of the content
        if let quote = store.celebrationQuote {
            VStack {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.barbiePink)
                    Text(quote.text)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkPrimary)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blushMid)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.barbiePink.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .allowsHitTesting(false)

                Spacer()
            }
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
        .background(Color.blush)
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
                    withAnimation(.smooth(duration: 0.25)) {
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
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onTapGesture {
                withAnimation(.smooth(duration: 0.25)) {
                    store.dismissToast()
                }
            }
            .onAppear {
                withAnimation(.smooth(duration: 0.3)) {
                    toastScale = 1.0
                }
            }
        }
    }
}
