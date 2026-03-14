import SwiftUI

struct TaskRowView: View {
    @Environment(Store.self) private var store
    @Environment(AppSettings.self) private var settings
    let task: BarbieTask

    private var isSelected: Bool { store.selectedTaskIds.contains(task.id) }
    private var isTrashView: Bool {
        if case .smartList(.trash) = store.selectedView { return true }
        return false
    }

    @State private var isHovered = false
    @State private var showDeleteConfirm = false
    @State private var completionFlash: Double = 0
    @State private var rowScale: CGFloat = 1.0
    @State private var checkBounce: CGFloat = 1.0
    @State private var showRipple = false
    @State private var showSparkle = false

    var body: some View {
        // KEY DESIGN: Checkbox and action buttons are SEPARATE from the
        // selectable area. No shared gesture recognizers. No conflicts.
        // The checkbox ALWAYS works, no matter what.
        HStack(alignment: .top, spacing: 0) {
            // ── Checkbox: standalone, no gesture conflicts ──
            checkboxButton
                .zIndex(1)

            // ── Selectable area: title, badges, indicators ──
            selectableArea
                .padding(.leading, 10)

            // ── Action buttons: trash/restore, also standalone ──
            actionButtons
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(rowBackground)
        .overlay(alignment: .topLeading) { multiSelectBadge }
        .scaleEffect(rowScale)
        .shadow(color: isHovered ? Color.barbiePink.opacity(0.08) : .clear, radius: 8, y: 2)
        .onHover { isHovered = $0 }
        .animation(.smooth(duration: 0.3), value: isHovered)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(taskAccessibilityLabel)
        .accessibilityAction(.default) { completeTask() }
        .onChange(of: task.isDone) { old, new in
            if new && !old {
                withAnimation(.smooth(duration: 0.4)) {
                    completionFlash = 0.3
                    rowScale = 0.97
                }
                withAnimation(.smooth(duration: 0.7).delay(0.25)) {
                    completionFlash = 0
                    rowScale = 1.0
                }
            }
        }
        .contextMenu { contextMenuItems }
        .confirmationDialog("Delete permanently?", isPresented: $showDeleteConfirm) {
            Button("Delete Forever", role: .destructive) {
                store.permanentlyDelete(task.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This task will be permanently removed and cannot be recovered.")
        }
    }

    // MARK: - Selectable Area (title, badges — handles row selection on tap)

    private var selectableArea: some View {
        HStack(alignment: .top, spacing: 4) {
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(task.isDone ? Color.inkMuted : Color.inkPrimary)
                    .strikethrough(task.isDone, color: .inkMuted)
                    .lineLimit(2)
                    .animation(.smooth(duration: 0.45), value: task.isDone)

                if hasMeta { metaBadges }
            }

            Spacer(minLength: 4)

            if task.recurrence != nil && !task.isDone {
                Image(systemName: "repeat")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.inkMuted)
            }

            if !task.attachments.isEmpty {
                Image(systemName: "paperclip")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.inkMuted)
            }
        }
        .contentShape(Rectangle())
        .draggable(task.id.uuidString)
        .onTapGesture {
            // This ONLY handles selection — never completion.
            // Checkbox is a separate view with its own Button.
            if NSEvent.modifierFlags.contains(.command) {
                if store.selectedTaskIds.contains(task.id) {
                    store.selectedTaskIds.remove(task.id)
                } else {
                    store.selectedTaskIds.insert(task.id)
                }
            } else if settings.autoOpenDetail {
                // Auto-open: clicking toggles the detail panel
                withAnimation(.smooth(duration: 0.3)) {
                    store.selectedTaskId = (store.selectedTaskId == task.id) ? nil : task.id
                }
            } else {
                // Manual mode: clicking just highlights, use detail button to open panel
                withAnimation(.smooth(duration: 0.3)) {
                    if store.selectedTaskId == task.id {
                        store.selectedTaskId = nil
                    }
                    // Just highlight the row but don't open detail
                }
            }
        }
    }

    // MARK: - Action Buttons (detail, trash, restore — separate hit targets)

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 4) {
            if isTrashView {
                Button { store.restoreTask(task.id) } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.inkMuted)
                }
                .buttonStyle(.plain).help("Restore")
            }

            // Detail/edit button
            if !isTrashView {
                Button {
                    withAnimation(.smooth(duration: 0.3)) {
                        store.selectedTaskId = task.id
                    }
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.barbiePink.opacity(0.6))
                }
                .buttonStyle(.plain)
                .opacity(isSelected || isHovered ? 1 : 0)
                .animation(.smooth(duration: 0.25), value: isHovered)
                .help("Open details")
            }

            Button {
                if isTrashView {
                    showDeleteConfirm = true
                } else {
                    withAnimation(.smooth(duration: 0.5)) {
                        store.trashTask(task.id)
                    }
                }
            } label: {
                Image(systemName: isTrashView ? "xmark" : "trash")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkMuted.opacity(0.5))
            }
            .buttonStyle(.plain)
            .opacity(isSelected || isHovered ? 1 : 0)
            .animation(.smooth(duration: 0.25), value: isHovered)
            .help(isTrashView ? "Delete" : "Trash")
        }
    }

    // MARK: - Background

    private var rowBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.blush : (isHovered ? Color.blush.opacity(0.5) : Color.clear))
                .animation(.smooth(duration: 0.25), value: isHovered)

            RoundedRectangle(cornerRadius: 10)
                .fill(Color.barbiePink.opacity(completionFlash))
        }
    }

    @ViewBuilder
    private var multiSelectBadge: some View {
        if store.selectedTaskIds.contains(task.id) && store.selectedTaskIds.count > 1 {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.barbiePink)
                .padding(.leading, 4)
                .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Checkbox (ALWAYS works — isolated Button, no shared gestures)

    private func completeTask() {
        let wasDone = task.isDone

        withAnimation(.smooth(duration: 0.5)) {
            store.toggleTask(task.id)
        }

        if !wasDone {
            showRipple = true
            showSparkle = true

            withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) {
                checkBounce = 1.35
            }
            withAnimation(.smooth(duration: 0.5).delay(0.18)) {
                checkBounce = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showRipple = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                showSparkle = false
            }
        }
    }

    private var checkboxButton: some View {
        Button {
            completeTask()
        } label: {
            ZStack {
                if showRipple {
                    CheckmarkRipple()
                }

                if showSparkle {
                    SparkleBurst(count: 8)
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
            .frame(width: 28, height: 28) // Generous tap target
            .contentShape(Circle().scale(1.5)) // Even bigger hit area
        }
        .buttonStyle(.plain)
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
        || (task.isDone && task.doneAt != nil && settings.autoCompletionTimestamp)
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

            if task.isDone, let doneAt = task.doneAt, settings.autoCompletionTimestamp {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle").font(.system(size: 9))
                    Text(doneAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                }
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.barbieRose)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.barbieRose.opacity(0.1), in: Capsule())
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

    // MARK: - Context Menu

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
