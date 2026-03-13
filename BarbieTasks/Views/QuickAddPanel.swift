import SwiftUI
import AppKit

// MARK: - Panel Controller

/// Manages a floating NSPanel for quick task entry triggered by the global hotkey.
final class QuickAddPanelController {
    static let shared = QuickAddPanelController()

    private var panel: NSPanel?
    private var isVisible = false
    private var clickMonitor: Any?

    private init() {}

    /// Toggles the quick-add panel visibility.
    func toggle(store: Store) {
        if isVisible {
            hide()
        } else {
            show(store: store)
        }
    }

    private func show(store: Store) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 160),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(
            rootView: QuickAddPanelView(dismiss: { [weak self] in self?.hide() })
                .environment(store)
        )
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.panel = panel
        isVisible = true

        // Dismiss when clicking outside the panel
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self, let panel = self.panel else { return }
            let location = event.locationInWindow
            if !panel.frame.contains(location) {
                self.hide()
            }
        }
    }

    private func hide() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
        panel?.close()
        panel = nil
        isVisible = false
    }
}

// MARK: - Quick Add View

struct QuickAddPanelView: View {
    @Environment(Store.self) private var store
    @State private var taskText = ""
    @State private var parsedResult: NaturalDateParser.ParseResult?

    var dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Text field
            TextField("Quick add a task...", text: $taskText)
                .textFieldStyle(.plain)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkPrimary)
                .padding(14)
                .background(Color.blushMid)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.petal, lineWidth: 1)
                )
                .onSubmit { addTask() }
                .onChange(of: taskText) { _, newValue in
                    parsedResult = newValue.isEmpty ? nil : NaturalDateParser.parse(newValue)
                }

            // Natural language preview
            if let result = parsedResult {
                HStack(spacing: 8) {
                    if !result.title.isEmpty {
                        previewPill(label: "Task", value: result.title, icon: "checkmark.circle")
                    }
                    if let date = result.dueDate {
                        previewPill(
                            label: "Due",
                            value: date.formatted(date: .abbreviated, time: .omitted),
                            icon: "calendar"
                        )
                    }
                    if result.priority > 0 {
                        previewPill(label: "Priority", value: "\(result.priority)", icon: "flag.fill")
                    }
                    if let project = result.projectName {
                        previewPill(label: "Project", value: project, icon: "folder")
                    }
                    if !result.tagNames.isEmpty {
                        previewPill(label: "Tags", value: result.tagNames.joined(separator: ", "), icon: "tag")
                    }
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
            }

            // Template quick-pick
            if !store.templates.isEmpty {
                Divider()
                    .overlay(Color.petalLight)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.templates) { template in
                            Button {
                                store.createFromTemplate(template.id)
                                dismiss()
                            } label: {
                                Text(template.name)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.barbieDeep)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.barbiePink.opacity(0.12))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.barbieRose.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Hint text
            HStack(spacing: 16) {
                hintLabel("Return", description: "Add task")
                hintLabel("Esc", description: "Dismiss")
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .background(Color.blush)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.petal, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        .onExitCommand { dismiss() }
    }

    // MARK: - Helpers

    private func addTask() {
        let text = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        store.addTask(title: text)
        dismiss()
    }

    private func previewPill(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(Color.barbiePink)
            Text(value)
                .foregroundStyle(Color.inkSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blushMid)
        .clipShape(Capsule())
    }

    private func hintLabel(_ key: String, description: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkMuted)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blushMid)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.petal, lineWidth: 0.5)
                )
            Text(description)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkMuted)
        }
    }
}
