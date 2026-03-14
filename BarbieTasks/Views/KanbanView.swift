import SwiftUI
import UniformTypeIdentifiers

struct KanbanView: View {
    @Environment(Store.self) private var store
    @State private var draggingTaskId: UUID?
    @State private var dropTargetStatus: BarbieTask.Status?

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with view toggle
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.split.3x1")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.barbiePink)
                    Text("Kanban")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkPrimary)
                }

                Spacer()

                Button {
                    withAnimation(.smooth(duration: 0.4)) { store.viewMode = .list }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 11, weight: .bold))
                        Text("List View")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Color.barbiePink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blushMid, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            inlineCelebrations

            HStack(alignment: .top, spacing: 16) {
                ForEach(BarbieTask.Status.allCases) { status in
                    kanbanColumn(for: status)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Column

    @ViewBuilder
    private func kanbanColumn(for status: BarbieTask.Status) -> some View {
        let tasks = store.kanbanTasks(for: status)
        let isDropTarget = dropTargetStatus == status

        VStack(alignment: .leading, spacing: 0) {
            columnHeader(status: status, count: tasks.count)
                .padding(.bottom, 10)

            ScrollView(.vertical) {
                LazyVStack(spacing: 8) {
                    if tasks.isEmpty && draggingTaskId == nil {
                        emptyState(for: status)
                    } else {
                        ForEach(tasks) { task in
                            KanbanCard(
                                task: task,
                                isSelected: store.selectedTaskId == task.id,
                                isDragging: draggingTaskId == task.id
                            ) {
                                store.selectedTaskId = task.id
                            } onDragStart: {
                                draggingTaskId = task.id
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
                .animation(.smooth(duration: 0.35), value: tasks.map(\.id))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDropTarget ? Color.barbiePink.opacity(0.5) : Color.clear, lineWidth: 2)
                .animation(.smooth(duration: 0.2), value: isDropTarget)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(status.label) column, \(tasks.count) tasks")
        .onDrop(of: [.plainText], isTargeted: Binding(
            get: { dropTargetStatus == status },
            set: { targeted in
                if targeted {
                    dropTargetStatus = status
                } else if dropTargetStatus == status {
                    dropTargetStatus = nil
                }
            }
        )) { providers in
            guard let provider = providers.first else { return false }
            provider.loadObject(ofClass: NSString.self) { nsString, _ in
                guard let idString = nsString as? String,
                      let id = UUID(uuidString: idString) else { return }
                DispatchQueue.main.async {
                    withAnimation(.smooth(duration: 0.35)) {
                        store.setTaskStatus(id, to: status)
                        draggingTaskId = nil
                    }
                }
            }
            return true
        }
    }

    // MARK: - Column Header

    @ViewBuilder
    private func columnHeader(status: BarbieTask.Status, count: Int) -> some View {
        let color = headerColor(for: status)

        HStack(spacing: 6) {
            Image(systemName: status.icon)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(color)

            Text(status.label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(color)

            Spacer()

            Text("\(count)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(color.opacity(0.7))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.1), in: Capsule())
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Task Card

    private struct KanbanCard: View {
        @Environment(Store.self) private var store
        let task: BarbieTask
        let isSelected: Bool
        let isDragging: Bool
        let onTap: () -> Void
        let onDragStart: () -> Void
        @State private var isHovered = false

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if task.priority != .none {
                        BarbieIcon.Priority(priority: task.priority, size: 9)
                    }
                    Text(task.title)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.inkPrimary)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                }
                HStack(spacing: 8) {
                    if let due = task.formattedDue {
                        Label(due, systemImage: "calendar")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundStyle(task.isOverdue ? Color.priHigh : Color.inkMuted)
                    }
                    if let project = store.project(for: task) {
                        Text(project.title)
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.inkSecondary)
                    }
                    Spacer(minLength: 0)
                    if let progress = task.subtaskProgress {
                        Text(progress)
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.inkMuted)
                    }
                }
            }
            .padding(10)
            .background(Color.blushMid, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.barbiePink : Color.petal, lineWidth: isSelected ? 1.5 : 0.5)
            )
            .shadow(color: isHovered ? Color.barbiePink.opacity(0.15) : Color.clear, radius: 6, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isHovered && !isSelected ? Color.barbiePink.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .opacity(isDragging ? 0 : 1)
            .animation(.smooth(duration: 0.25), value: isHovered)
            .animation(.smooth(duration: 0.2), value: isDragging)
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .onHover { isHovered = $0 }
            .onTapGesture { onTap() }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(kanbanCardAccessibilityLabel)
            .accessibilityHint("Drag to move between columns, or double tap to select")
            .onDrag {
                onDragStart()
                return NSItemProvider(object: task.id.uuidString as NSString)
            }
        }

        private var kanbanCardAccessibilityLabel: String {
            var parts: [String] = [task.title]
            if task.priority != .none {
                parts.append("\(task.priority.label) priority")
            }
            if let due = task.formattedDue {
                parts.append("Due \(due)")
            }
            return parts.joined(separator: ", ")
        }
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
                            .contentTransition(.interpolate)
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
                    .rippleEffect(trigger: quote.id)
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

    // MARK: - Empty State

    @ViewBuilder
    private func emptyState(for status: BarbieTask.Status) -> some View {
        VStack(spacing: 6) {
            BarbieIcon.EmptyState(systemName: status.icon, size: 20)

            Text("No tasks")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(Color.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Helpers

    private func headerColor(for status: BarbieTask.Status) -> Color {
        switch status {
        case .todo: .inkMuted
        case .inProgress: .barbiePink
        case .done: .barbieRose
        }
    }
}

#Preview {
    KanbanView()
        .environment(Store())
        .frame(width: 800, height: 500)
}
