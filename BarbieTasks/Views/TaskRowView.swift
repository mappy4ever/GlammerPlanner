import SwiftUI

struct TaskRowView: View {
    @Environment(Store.self) private var store
    let task: BarbieTask

    private var isSelected: Bool { store.selectedTaskIds.contains(task.id) }
    private var isTrashView: Bool {
        if case .smartList(.trash) = store.selectedView { return true }
        return false
    }

    @State private var isHovered = false
    @State private var showDeleteConfirm = false
    @State private var completionFlash: Double = 0

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            checkbox

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(task.isDone ? Color.inkMuted : Color.inkPrimary)
                    .strikethrough(task.isDone, color: .inkMuted)
                    .lineLimit(2)
                    .animation(.smooth(duration: 0.3), value: task.isDone)

                if hasMeta { metaBadges }
            }

            Spacer(minLength: 4)

            // Recurrence indicator
            if task.recurrence != nil && !task.isDone {
                Image(systemName: "repeat")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.inkMuted)
            }

            // Attachment indicator
            if !task.attachments.isEmpty {
                Image(systemName: "paperclip")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.inkMuted)
            }

            if isTrashView {
                Button { store.restoreTask(task.id) } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.inkMuted)
                }
                .buttonStyle(.plain).help("Restore")
            }

            Button {
                if isTrashView {
                    showDeleteConfirm = true
                } else {
                    store.trashTask(task.id)
                }
            } label: {
                Image(systemName: isTrashView ? "xmark" : "trash")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkMuted.opacity(0.5))
            }
            .buttonStyle(.plain)
            .opacity(isSelected || isHovered ? 1 : 0)
            .help(isTrashView ? "Delete" : "Trash")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blush : (isHovered ? Color.blush.opacity(0.5) : Color.clear))

                // Completion flash
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.barbiePink.opacity(completionFlash))
            }
        )
        .overlay(alignment: .topLeading) {
            if store.selectedTaskIds.contains(task.id) && store.selectedTaskIds.count > 1 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.barbiePink)
                    Spacer()
                }
                .padding(.leading, 4)
            }
        }
        .onHover { isHovered = $0 }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(taskAccessibilityLabel)
        .accessibilityAction(.default) { store.toggleTask(task.id) }
        .onChange(of: task.isDone) { old, new in
            if new && !old {
                // Flash pink on completion
                withAnimation(.smooth(duration: 0.15)) {
                    completionFlash = 0.15
                }
                withAnimation(.smooth(duration: 0.5).delay(0.15)) {
                    completionFlash = 0
                }
            }
        }
        .onTapGesture {
            if NSEvent.modifierFlags.contains(.command) {
                // Multi-select
                if store.selectedTaskIds.contains(task.id) {
                    store.selectedTaskIds.remove(task.id)
                } else {
                    store.selectedTaskIds.insert(task.id)
                }
            } else {
                withAnimation(.smooth(duration: 0.2)) {
                    store.selectedTaskId = (store.selectedTaskId == task.id) ? nil : task.id
                }
            }
        }
        .contextMenu { contextMenuItems }
        .draggable(task.id.uuidString)
        .confirmationDialog("Delete permanently?", isPresented: $showDeleteConfirm) {
            Button("Delete Forever", role: .destructive) {
                store.permanentlyDelete(task.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This task will be permanently removed and cannot be recovered.")
        }
    }

    // MARK: - Checkbox

    @State private var checkBounce: CGFloat = 1.0
    @State private var showRipple = false

    private var checkbox: some View {
        Button {
            let wasDone = task.isDone
            withAnimation(.smooth(duration: 0.3)) {
                store.toggleTask(task.id)
            }
            // Trigger bounce + ripple only on completion
            if !wasDone {
                showRipple = true
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    checkBounce = 1.2
                }
                withAnimation(.smooth(duration: 0.2).delay(0.12)) {
                    checkBounce = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showRipple = false
                }
            }
        } label: {
            ZStack {
                // Ripple ring
                if showRipple {
                    CheckmarkRipple()
                }

                Circle()
                    .stroke(checkboxBorderColor, lineWidth: 2)
                    .frame(width: 20, height: 20)

                if task.isDone {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.barbiePink, .barbieDeep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 20, height: 20)
                        .transition(.scale.combined(with: .opacity))

                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                }
            }
            .scaleEffect(checkBounce)
        }
        .buttonStyle(.plain)
        .padding(.top, 1)
        .accessibilityLabel(task.isDone ? "Completed" : "Incomplete")
        .accessibilityHint("Double tap to toggle completion")
    }

    private var checkboxBorderColor: Color {
        if task.isDone { return .barbieDeep }
        switch task.priority {
        case .high: return .priHigh
        case .medium: return .priMed
        case .low: return .priLow
        case .none: return .petal
        }
    }

    // MARK: - Meta

    private var hasMeta: Bool {
        task.formattedDue != nil
        || (!isProjectView && task.projectId != nil)
        || task.subtaskProgress != nil
        || !task.tagIds.isEmpty
        || task.isInProgress
    }

    private var isProjectView: Bool {
        if case .project = store.selectedView { return true }
        return false
    }

    private var metaBadges: some View {
        HStack(spacing: 5) {
            if task.isInProgress && !task.isDone {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.right.circle.fill").font(.system(size: 9))
                    Text("In Progress")
                }
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.barbiePink, in: Capsule())
            }

            if let due = task.formattedDue, !task.isDone {
                HStack(spacing: 3) {
                    Image(systemName: "calendar").font(.system(size: 9))
                    Text(due)
                }
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(dueBadgeColor)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(dueBadgeBg, in: Capsule())
            }

            if !isProjectView, let proj = store.project(for: task) {
                HStack(spacing: 3) {
                    Circle().fill(proj.color).frame(width: 6, height: 6)
                    Text(proj.title)
                }
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.inkSecondary)
                .lineLimit(1)
            }

            // Tags
            ForEach(store.tagsForTask(task).prefix(3)) { tag in
                HStack(spacing: 3) {
                    Circle()
                        .fill(tag.color)
                        .frame(width: 5, height: 5)
                    Text(tag.name)
                }
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(tag.color)
                .padding(.horizontal, 7).padding(.vertical, 2)
                .background(tag.color.opacity(0.12), in: Capsule())
                .overlay(Capsule().strokeBorder(tag.color.opacity(0.25), lineWidth: 0.5))
            }

            if let sub = task.subtaskProgress {
                HStack(spacing: 3) {
                    Image(systemName: "checklist").font(.system(size: 9))
                    Text(sub)
                }
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.inkMuted)
            }

            if task.pomodoroCount > 0 {
                HStack(spacing: 2) {
                    BarbieIcon.Timer(size: 9)
                    Text("\(task.pomodoroCount)")
                }
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.inkMuted)
            }
        }
    }

    private var dueBadgeColor: Color {
        if task.isOverdue { return Color(hex: "#C25050") }
        if task.isDueToday { return .white }
        return Color.inkSecondary
    }

    private var dueBadgeBg: Color {
        if task.isOverdue { return Color(hex: "#FBEAEA") }
        if task.isDueToday { return .barbiePink }
        return Color.blush
    }

    // MARK: - Context Menu

    // MARK: - Accessibility

    private var taskAccessibilityLabel: String {
        var parts: [String] = [task.title]
        parts.append(task.isDone ? "Completed" : "Incomplete")
        if task.priority != .none {
            parts.append("\(task.priority.label) priority")
        }
        if let due = task.formattedDue {
            parts.append("Due \(due)")
        }
        if task.isOverdue {
            parts.append("Overdue")
        }
        return parts.joined(separator: ", ")
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        if !isTrashView {
            Button(task.isDone ? "Uncomplete" : "Complete") { store.toggleTask(task.id) }
            Divider()

            Menu("Priority") {
                ForEach(BarbieTask.Priority.allCases) { p in
                    Button {
                        store.update(task.id) { $0.priority = p }
                    } label: {
                        if task.priority == p { Image(systemName: "checkmark") }
                        Text(p.label)
                    }
                }
            }

            if !store.projects.isEmpty {
                Menu("Move to Project") {
                    Button("Inbox") { store.update(task.id) { $0.projectId = nil } }
                    Divider()
                    ForEach(store.projects) { proj in
                        Button(proj.title) { store.update(task.id) { $0.projectId = proj.id } }
                    }
                }
            }

            Menu("Due Date") {
                Button("Today") {
                    store.update(task.id) { $0.dueDate = Calendar.current.startOfDay(for: Date()) }
                }
                Button("Tomorrow") {
                    store.update(task.id) { $0.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) }
                }
                Button("Next Week") {
                    store.update(task.id) { $0.dueDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Calendar.current.startOfDay(for: Date())) }
                }
                if task.dueDate != nil {
                    Divider()
                    Button("Remove Date") { store.update(task.id) { $0.dueDate = nil } }
                }
            }

            Menu("Status") {
                ForEach(BarbieTask.Status.allCases) { s in
                    Button {
                        store.setTaskStatus(task.id, to: s)
                    } label: {
                        if task.status == s { Image(systemName: "checkmark") }
                        Label(s.label, systemImage: s.icon)
                    }
                }
            }

            if task.dueDate != nil && task.calendarEventId == nil {
                Button("Add to Calendar") { store.addTaskToCalendar(task.id) }
            }

            Divider()

            Button("Duplicate") { store.duplicateTask(task.id) }

            Button("Save as Template...") {
                store.saveAsTemplateTaskId = task.id
            }

            Divider()
            Button("Move to Trash", role: .destructive) { store.trashTask(task.id) }
        } else {
            Button("Restore") { store.restoreTask(task.id) }
            Button("Delete Permanently", role: .destructive) { showDeleteConfirm = true }
        }
    }
}
