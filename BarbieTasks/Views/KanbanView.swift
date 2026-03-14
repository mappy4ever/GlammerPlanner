import SwiftUI

struct KanbanView: View {
    @Environment(Store.self) private var store
    @State private var columnDropTargets: Set<BarbieTask.Status> = []

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
        let isColumnDropTarget = columnDropTargets.contains(status)

        VStack(alignment: .leading, spacing: 0) {
            columnHeader(status: status, count: tasks.count)
                .padding(.bottom, 10)

            ScrollView(.vertical) {
                LazyVStack(spacing: 8) {
                    if tasks.isEmpty {
                        emptyState(for: status)
                    } else {
                        ForEach(tasks) { task in
                            KanbanCard(task: task, isSelected: store.selectedTaskId == task.id) {
                                store.selectedTaskId = task.id
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isColumnDropTarget ? Color.barbiePink.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(status.label) column, \(tasks.count) tasks")
        .dropDestination(for: String.self) { droppedItems, _ in
            guard let idString = droppedItems.first,
                  let id = UUID(uuidString: idString) else { return false }
            withAnimation(.smooth(duration: 0.4)) {
                store.setTaskStatus(id, to: status)
            }
            return true
        } isTargeted: { isTargeted in
            if isTargeted {
                columnDropTargets.insert(status)
            } else {
                columnDropTargets.remove(status)
            }
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
        let onTap: () -> Void
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
            .animation(.smooth(duration: 0.25), value: isHovered)
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .onHover { isHovered = $0 }
            .onTapGesture { onTap() }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(kanbanCardAccessibilityLabel)
            .accessibilityHint("Drag to move between columns, or double tap to select")
            .draggable(task.id.uuidString)
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

    private func priorityColor(_ p: BarbieTask.Priority) -> Color {
        switch p {
        case .high: .priHigh
        case .medium: .priMed
        case .low: .priLow
        case .none: .petal
        }
    }
}

#Preview {
    KanbanView()
        .environment(Store())
        .frame(width: 800, height: 500)
}
