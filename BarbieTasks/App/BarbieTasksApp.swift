import SwiftUI
import AppKit
import UserNotifications

@main
struct BarbieTasksApp: App {
    @State private var store = Store.load()
    @State private var settings = AppSettings()
    @State private var showShortcuts = false

    var body: some Scene {
        // Main window
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(settings)
                .frame(minWidth: 780, minHeight: 480)
                .preferredColorScheme(settings.preferredColorScheme)
                .onAppear {
                    NotificationService.shared.registerActions()
                    Task {
                        await NotificationService.shared.requestPermission()
                    }
                    // Register global hotkey (Ctrl+Space)
                    HotkeyService.shared.register {
                        QuickAddPanelController.shared.toggle(store: store)
                    }
                }
                .onOpenURL { url in
                    handleURL(url)
                }
                .background(WindowFrameRestorer())
                .sheet(isPresented: Binding(
                    get: { !settings.hasCompletedOnboarding },
                    set: { if !$0 { settings.hasCompletedOnboarding = true } }
                )) {
                    OnboardingView()
                        .environment(settings)
                }
                .sheet(isPresented: $showShortcuts) {
                    ShortcutsHelpView()
                }
        }
        .defaultSize(width: 1080, height: 680)
        .commands {
            CommandGroup(replacing: .undoRedo) {
                Button("Undo \(store.undoActionName ?? "")") {
                    store.performUndo()
                }
                .keyboardShortcut("z")
                .disabled(!store.canUndo)

                Button("Redo \(store.redoActionName ?? "")") {
                    store.performRedo()
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!store.canRedo)
            }

            CommandGroup(replacing: .newItem) {
                Button("New Task") { store.focusQuickAdd = true }
                    .keyboardShortcut("n")

                Button("New Project") { store.showNewProject = true }
                    .keyboardShortcut("n", modifiers: [.command, .shift])

                Divider()

                Button("Find") { store.focusSearch = true }
                    .keyboardShortcut("f")

                Button("Command Palette") { store.showCommandPalette = true }
                    .keyboardShortcut("k")

                Divider()

                Button("Templates...") { store.showTemplateManager = true }
                    .keyboardShortcut("t", modifiers: [.command, .shift])

                Divider()

                Button("Duplicate") { if let id = store.selectedTaskId { store.duplicateTask(id) } }
                    .keyboardShortcut("d")
                    .disabled(store.selectedTaskId == nil)

                Divider()

                Button("Select All") { store.selectAll() }
                    .keyboardShortcut("a")
            }

            CommandGroup(after: .sidebar) {
                Picker("Sort By", selection: $store.sortBy) {
                    ForEach(SortOption.allCases) { opt in
                        Text(opt.label).tag(opt)
                    }
                }

                Toggle("Show Completed", isOn: $store.showCompleted)
                    .keyboardShortcut("e", modifiers: [.command, .shift])

                Divider()

                Button("Switch to Inbox") { store.selectedView = .smartList(.inbox) }
                    .keyboardShortcut("1")
                Button("Switch to Today") { store.selectedView = .smartList(.today) }
                    .keyboardShortcut("2")
                Button("Switch to Upcoming") { store.selectedView = .smartList(.upcoming) }
                    .keyboardShortcut("3")
                Button("Switch to All Tasks") { store.selectedView = .smartList(.anytime) }
                    .keyboardShortcut("4")
            }

            CommandGroup(replacing: .help) {
                Button("Keyboard Shortcuts") {
                    showShortcuts = true
                }
            }
        }

        // Settings window
        Settings {
            SettingsView()
                .environment(store)
                .environment(settings)
        }

        // Menu bar quick-add
        MenuBarExtra {
            MenuBarView()
                .environment(store)
                .environment(settings)
        } label: {
            Image(systemName: "checkmark.circle")
            if store.count(for: .smartList(.today)) > 0 {
                Text("\(store.count(for: .smartList(.today)))")
            }
        }
    }

    // MARK: - URL Scheme

    private func handleURL(_ url: URL) {
        guard url.scheme == "barbietasks" else { return }
        switch url.host {
        case "add":
            if let title = url.queryValue(for: "title") {
                store.addTask(title: title)
            }
        case "show":
            let path = url.pathComponents.dropFirst().first
            switch path {
            case "inbox": store.selectedView = .smartList(.inbox)
            case "today": store.selectedView = .smartList(.today)
            case "upcoming": store.selectedView = .smartList(.upcoming)
            default: break
            }
        default:
            break
        }
    }
}

// MARK: - Menu Bar View

struct MenuBarView: View {
    @Environment(Store.self) private var store
    @State private var quickText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Slay List")
                .font(.system(size: 13, weight: .bold, design: .rounded))

            TextField("Quick add...", text: $quickText)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    if !quickText.isEmpty {
                        store.addTask(title: quickText)
                        quickText = ""
                    }
                }

            Divider()

            let todayTasks = store.activeTasks.filter { !$0.isDone && ($0.isDueToday || $0.isOverdue) }
            if todayTasks.isEmpty {
                Text("Nothing due today!")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(todayTasks.prefix(8)) { task in
                    HStack(spacing: 6) {
                        Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 12))
                            .foregroundStyle(task.isOverdue ? .red : .pink)
                        Text(task.title)
                            .font(.system(size: 12, design: .rounded))
                            .lineLimit(1)
                    }
                }
            }

            Divider()

            Button("Open Slay List") {
                NSApplication.shared.activate(ignoringOtherApps: true)
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(12)
        .frame(width: 240)
    }
}

// URL query helper
extension URL {
    func queryValue(for key: String) -> String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == key }?.value
    }
}

// MARK: - Window Frame Restoration

struct WindowFrameRestorer: NSViewRepresentable {
    private static let key = "mainWindowFrame"

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            // Restore saved frame
            if let saved = UserDefaults.standard.string(forKey: Self.key) {
                let parts = saved.split(separator: ",").compactMap { Double($0) }
                if parts.count == 4 {
                    let frame = NSRect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
                    window.setFrame(frame, display: true)
                }
            }
            // Observe move & resize to persist frame
            NotificationCenter.default.addObserver(
                context.coordinator, selector: #selector(Coordinator.windowDidChangeFrame(_:)),
                name: NSWindow.didMoveNotification, object: window
            )
            NotificationCenter.default.addObserver(
                context.coordinator, selector: #selector(Coordinator.windowDidChangeFrame(_:)),
                name: NSWindow.didResizeNotification, object: window
            )
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
        @objc func windowDidChangeFrame(_ notification: Notification) {
            guard let window = notification.object as? NSWindow else { return }
            let f = window.frame
            let value = "\(f.origin.x),\(f.origin.y),\(f.size.width),\(f.size.height)"
            UserDefaults.standard.set(value, forKey: WindowFrameRestorer.key)
        }
    }
}

// MARK: - Keyboard Shortcuts Help

private struct ShortcutsHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Keyboard Shortcuts")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.barbiePink)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.inkMuted)
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: [GridItem(.fixed(160)), GridItem(.fixed(160))], spacing: 10) {
                shortcutRow("Cmd+N", "New Task")
                shortcutRow("Cmd+K", "Command Palette")
                shortcutRow("Ctrl+Space", "Quick Add")
                shortcutRow("Cmd+D", "Duplicate Task")
                shortcutRow("Cmd+Z", "Undo")
                shortcutRow("Cmd+Shift+Z", "Redo")
                shortcutRow("Cmd+A", "Select All")
                shortcutRow("Cmd+1-4", "Switch Views")
                shortcutRow("Space", "Toggle Complete")
                shortcutRow("Delete", "Trash Task")
                shortcutRow("Arrow Keys", "Navigate Tasks")
                shortcutRow("Escape", "Deselect")
                shortcutRow("Cmd+Shift+N", "New Project")
                shortcutRow("Cmd+Shift+T", "Templates")
                shortcutRow("Cmd+Shift+E", "Show Completed")
                shortcutRow("Cmd+,", "Settings")
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(Color.blush)
    }

    private func shortcutRow(_ key: String, _ action: String) -> some View {
        HStack(spacing: 8) {
            Text(key)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.inkMuted)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.blushMid, in: RoundedRectangle(cornerRadius: 4))
            Text(action)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkPrimary)
            Spacer()
        }
    }
}
