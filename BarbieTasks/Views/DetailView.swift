import SwiftUI

struct DetailView: View {
    @Environment(Store.self) private var store
    @Environment(AppSettings.self) private var settings
    let task: BarbieTask

    @State private var editTitle = ""
    @State private var editNotes = ""
    @State private var newSubtaskText = ""
    @State private var newAttachmentURL = ""
    @State private var draggingSubtaskId: UUID?
    @FocusState private var isSubtaskFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.smooth(duration: 0.25)) {
                            store.selectedTaskId = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.inkMuted.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .help("Close details")
                }
                .padding(.bottom, 4)

                titleSection
                Divider().padding(.vertical, 12)
                fieldsSection
                Divider().padding(.vertical, 12)
                notesSection
                Divider().padding(.vertical, 12)
                subtasksSection
                if !task.attachments.isEmpty || true {
                    Divider().padding(.vertical, 12)
                    attachmentsSection
                }
                Divider().padding(.vertical, 16)
                footerSection
            }
            .padding(16)
        }
        .background(Color.blush)
        .onAppear { syncFields() }
        .onChange(of: task.id) { syncFields() }
    }

    private func syncFields() {
        editTitle = task.title
        editNotes = task.notes
    }

    // MARK: - Title

    private var titleSection: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                withAnimation { store.toggleTask(task.id) }
            } label: {
                ZStack {
                    Circle()
                        .stroke(task.isDone ? Color.barbieDeep : Color.petal, lineWidth: 2.5)
                        .frame(width: 24, height: 24)
                    if task.isDone {
                        Circle()
                            .fill(LinearGradient(colors: [.barbiePink, .barbieDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain).padding(.top, 4)
            .accessibilityLabel(task.isDone ? "Mark incomplete" : "Mark complete")
            .accessibilityHint("Double tap to toggle completion")

            TextField("Task title...", text: $editTitle, axis: .vertical)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkPrimary)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .onChange(of: editTitle) { commitTitle() }
        }
    }

    private func commitTitle() {
        let t = editTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty && t != task.title { store.update(task.id) { $0.title = t } }
    }

    // MARK: - Fields

    private var fieldsSection: some View {
        VStack(spacing: 14) {
            // Due date
            fieldRow(icon: "calendar", label: "Due") {
                DatePicker("", selection: Binding(
                    get: { task.dueDate ?? Date() },
                    set: { newDate in store.update(task.id) { $0.dueDate = newDate } }
                ), displayedComponents: task.dueDate != nil ? [.date, .hourAndMinute] : [.date])
                .labelsHidden().datePickerStyle(.compact).tint(.barbiePink)
                .accessibilityLabel("Due date")

                if task.dueDate != nil {
                    Button { store.update(task.id) { $0.dueDate = nil } } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Color.inkMuted).font(.system(size: 14))
                    }.buttonStyle(.plain)
                }
            }

            // Quick date buttons
            HStack(spacing: 6) {
                dateShortcut("Today", date: Calendar.current.startOfDay(for: Date()))
                dateShortcut("Tomorrow", date: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!)
                dateShortcut("Next Week", date: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Calendar.current.startOfDay(for: Date()))!)
            }
            .padding(.leading, 30)

            // Completed at
            if task.isDone, let doneAt = task.doneAt, settings.autoCompletionTimestamp {
                fieldRow(icon: "checkmark.circle", label: "Done") {
                    Text(doneAt.formatted(.dateTime.month(.abbreviated).day().year().hour().minute()))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.barbieRose)
                    Spacer()
                    Button { store.update(task.id) { $0.doneAt = nil } } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Color.inkMuted).font(.system(size: 14))
                    }.buttonStyle(.plain).help("Remove timestamp")
                }
            }

            // Recurrence
            fieldRow(icon: "repeat", label: "Repeat") {
                if let rule = task.recurrence {
                    Text(rule.summary)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.barbiePink)
                    Button { store.update(task.id) { $0.recurrence = nil } } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Color.inkMuted).font(.system(size: 14))
                    }.buttonStyle(.plain)
                } else {
                    Menu("Add...") {
                        Button("Daily") { store.update(task.id) { $0.recurrence = RecurrenceRule(frequency: .daily) } }
                        Button("Weekly") { store.update(task.id) { $0.recurrence = RecurrenceRule(frequency: .weekly) } }
                        Button("Monthly") { store.update(task.id) { $0.recurrence = RecurrenceRule(frequency: .monthly) } }
                        Button("Yearly") { store.update(task.id) { $0.recurrence = RecurrenceRule(frequency: .yearly) } }
                    }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
            }

            // Priority
            fieldRow(icon: "arrow.up.arrow.down", label: "Priority") {
                HStack(spacing: 4) {
                    ForEach(BarbieTask.Priority.allCases) { p in
                        Button {
                            withAnimation(.easeOut(duration: 0.15)) { store.update(task.id) { $0.priority = p } }
                        } label: {
                            prioritySymbol(p)
                                .frame(width: 28, height: 28)
                                .background(task.priority == p ? priorityColor(p) : Color.blush, in: Circle())
                                .foregroundStyle(task.priority == p ? .white : Color.inkSecondary)
                        }
                        .buttonStyle(.plain)
                        .help(p.label)
                    }
                }
            }

            // Project
            fieldRow(icon: "folder", label: "Project") {
                Picker("", selection: Binding(
                    get: { task.projectId ?? UUID() },
                    set: { v in store.update(task.id) { $0.projectId = store.projects.contains { $0.id == v } ? v : nil } }
                )) {
                    Text("Inbox").tag(UUID())
                    ForEach(store.projects) { p in
                        HStack { Circle().fill(p.color).frame(width: 8, height: 8); Text(p.title) }.tag(p.id)
                    }
                }
                .labelsHidden().pickerStyle(.menu).tint(.inkSecondary)
                .accessibilityLabel("Project")
            }

            // Tags
            fieldRow(icon: "tag", label: "Tags") {
                FlowLayout(spacing: 4) {
                    ForEach(store.tagsForTask(task)) { tag in
                        HStack(spacing: 4) {
                            Circle().fill(tag.color).frame(width: 6, height: 6)
                            Text(tag.name)
                            Button { store.update(task.id) { $0.tagIds.removeAll { $0 == tag.id } } } label: {
                                Image(systemName: "xmark").font(.system(size: 7, weight: .bold))
                            }.buttonStyle(.plain)
                        }
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(tag.color)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(tag.color.opacity(0.12), in: Capsule())
                        .overlay(Capsule().strokeBorder(tag.color.opacity(0.25), lineWidth: 0.5))
                    }

                    let availableTags = store.tags.filter { !task.tagIds.contains($0.id) }
                    if !availableTags.isEmpty {
                        Menu("+") {
                            ForEach(availableTags) { tag in
                                Button(tag.name) { store.update(task.id) { $0.tagIds.append(tag.id) } }
                            }
                        }
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.barbiePink)
                    }
                }
            }

            // Reminder
            if task.dueDate != nil {
                fieldRow(icon: "bell", label: "Remind") {
                    Picker("", selection: Binding(
                        get: { task.reminderOffset ?? -1 },
                        set: { v in store.update(task.id) { $0.reminderOffset = v == -1 ? nil : v } }
                    )) {
                        Text("None").tag(-1)
                        Text("At time").tag(0)
                        Text("5 min before").tag(5)
                        Text("15 min before").tag(15)
                        Text("30 min before").tag(30)
                        Text("1 hour before").tag(60)
                        Text("1 day before").tag(1440)
                    }
                    .labelsHidden().pickerStyle(.menu).tint(.inkSecondary)
                    .accessibilityLabel("Reminder")
                }
            }

            // Calendar sync
            if task.dueDate != nil {
                fieldRow(icon: "calendar.badge.plus", label: "Calendar") {
                    if task.calendarEventId != nil {
                        HStack(spacing: 6) {
                            Text("Synced").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Color.barbiePink)
                            Button("Remove") { store.removeTaskFromCalendar(task.id) }
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.inkMuted)
                        }
                    } else {
                        Button("Add to Calendar") { store.addTaskToCalendar(task.id) }
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.barbiePink)
                    }
                }
            }

            // Pomodoro count
            fieldRow(icon: "timer", label: "Focus") {
                HStack(spacing: 8) {
                    Text("\(task.pomodoroCount) session\(task.pomodoroCount == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkSecondary)
                }
            }
        }
    }

    private func dateShortcut(_ label: String, date: Date) -> some View {
        Button { store.update(task.id) { $0.dueDate = date } } label: {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.blush, in: Capsule())
                .foregroundStyle(Color.barbiePink)
        }.buttonStyle(.plain)
    }

    private func fieldRow<Content: View>(icon: String, label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(Color.inkMuted).frame(width: 18)
            Text(label).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(Color.inkMuted).frame(width: 44, alignment: .leading)
            content()
            Spacer(minLength: 0)
        }
    }

    private func priorityColor(_ p: BarbieTask.Priority) -> Color {
        switch p {
        case .none: return .petal; case .low: return .priLow; case .medium: return .priMed; case .high: return .priHigh
        }
    }

    @ViewBuilder
    private func prioritySymbol(_ p: BarbieTask.Priority) -> some View {
        switch p {
        case .none:
            Image(systemName: "minus")
                .font(.system(size: 11, weight: .bold))
        case .low:
            Image(systemName: "arrow.down")
                .font(.system(size: 11, weight: .bold))
        case .medium:
            Image(systemName: "equal")
                .font(.system(size: 11, weight: .bold))
        case .high:
            Image(systemName: "arrow.up")
                .font(.system(size: 11, weight: .bold))
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Notes", systemImage: "note.text")
                .font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Color.inkMuted)
            TextEditor(text: $editNotes)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkPrimary)
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(minHeight: 80, maxHeight: 200)
                .background(Color.blushMid, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.petal, lineWidth: 1))
                .onChange(of: editNotes) {
                    if editNotes != task.notes { store.update(task.id) { $0.notes = editNotes } }
                }
        }
    }

    // MARK: - Subtasks

    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Subtasks", systemImage: "checklist")
                    .font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Color.inkMuted)
                if !task.subtasks.isEmpty {
                    Text(task.subtaskProgress ?? "")
                        .font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(Color.barbiePink)
                }
            }

            ForEach(Array(task.subtasks.enumerated()), id: \.element.id) { index, sub in
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.inkMuted.opacity(0.35))
                        .frame(width: 14)
                    Button { withAnimation(.easeOut(duration: 0.15)) { store.toggleSubtask(taskId: task.id, subtaskId: sub.id) } } label: {
                        ZStack {
                            Circle().stroke(sub.isDone ? Color.barbieDeep : Color.petal, lineWidth: 1.5).frame(width: 16, height: 16)
                            if sub.isDone {
                                Circle().fill(Color.barbiePink).frame(width: 16, height: 16)
                                Image(systemName: "checkmark").font(.system(size: 8, weight: .bold)).foregroundStyle(.white)
                            }
                        }
                    }.buttonStyle(.plain)
                    .accessibilityLabel(sub.isDone ? "Mark \(sub.text) incomplete" : "Mark \(sub.text) complete")
                    Text(sub.text)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(sub.isDone ? Color.inkMuted : Color.inkPrimary)
                        .strikethrough(sub.isDone, color: .inkMuted)
                    Spacer()
                    Button { store.deleteSubtask(taskId: task.id, subtaskId: sub.id) } label: {
                        Image(systemName: "xmark").font(.system(size: 9, weight: .medium)).foregroundStyle(Color.inkMuted.opacity(0.4))
                    }.buttonStyle(.plain)
                }
                .padding(.vertical, 3)
                .contentShape(Rectangle())
                .opacity(draggingSubtaskId == sub.id ? 0.4 : 1.0)
                .draggable(sub.id.uuidString) {
                    // Drag preview
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.inkMuted)
                        Text(sub.text)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.inkPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blush, in: RoundedRectangle(cornerRadius: 6))
                    .onAppear { draggingSubtaskId = sub.id }
                }
                .dropDestination(for: String.self) { items, _ in
                    guard let idString = items.first,
                          let draggedId = UUID(uuidString: idString),
                          draggedId != sub.id else { return false }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        store.update(task.id) { t in
                            guard let fromIndex = t.subtasks.firstIndex(where: { $0.id == draggedId }) else { return }
                            let item = t.subtasks.remove(at: fromIndex)
                            let toIndex = t.subtasks.firstIndex(where: { $0.id == sub.id }) ?? t.subtasks.endIndex
                            t.subtasks.insert(item, at: toIndex)
                        }
                    }
                    draggingSubtaskId = nil
                    return true
                } isTargeted: { targeted in
                    if !targeted && draggingSubtaskId != nil {
                        // Will reset when drag ends
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 11, weight: .medium)).foregroundStyle(Color.inkMuted)
                TextField("Add subtask...", text: $newSubtaskText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .focused($isSubtaskFocused)
                    .onSubmit {
                        if !newSubtaskText.isEmpty {
                            withAnimation { store.addSubtask(to: task.id, text: newSubtaskText); newSubtaskText = ""; isSubtaskFocused = true }
                        }
                    }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Attachments

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Attachments", systemImage: "paperclip")
                .font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Color.inkMuted)

            ForEach(task.attachments) { att in
                HStack(spacing: 8) {
                    Image(systemName: att.isLink ? "link" : "doc")
                        .font(.system(size: 12)).foregroundStyle(Color.barbiePink)
                    Text(att.name)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.inkPrimary)
                        .lineLimit(1)
                    Spacer()
                    if let url = att.url {
                        Button { NSWorkspace.shared.open(url) } label: {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.barbiePink)
                        }
                        .buttonStyle(.plain)
                        .help("Open attachment")
                    }
                    Button {
                        store.update(task.id) { $0.attachments.removeAll { $0.id == att.id } }
                    } label: {
                        Image(systemName: "xmark").font(.system(size: 9)).foregroundStyle(Color.inkMuted.opacity(0.4))
                    }.buttonStyle(.plain)
                }
                .padding(.vertical, 3)
            }

            HStack(spacing: 6) {
                TextField("Paste URL...", text: $newAttachmentURL)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .onSubmit {
                        if !newAttachmentURL.isEmpty {
                            let name = URL(string: newAttachmentURL)?.host ?? newAttachmentURL
                            store.update(task.id) {
                                $0.attachments.append(TaskAttachment(name: name, urlString: newAttachmentURL))
                            }
                            newAttachmentURL = ""
                        }
                    }
                Button("Add File...") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        store.update(task.id) {
                            $0.attachments.append(TaskAttachment(name: url.lastPathComponent, urlString: url.absoluteString))
                        }
                    }
                }
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.barbiePink)
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Created \(task.createdAt.formatted(.dateTime.month(.abbreviated).day().year()))")
                    .font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(Color.inkMuted)
                if task.updatedAt != task.createdAt {
                    Text("Modified \(task.updatedAt.formatted(.relative(presentation: .named)))")
                        .font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(Color.inkMuted.opacity(0.7))
                }
            }
            Spacer()
            Button {
                store.saveAsTemplateTaskId = task.id
            } label: {
                Label("Template", systemImage: "doc.on.doc")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkMuted)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.blush, in: Capsule())
            }.buttonStyle(.plain)
            Button { store.duplicateTask(task.id) } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkMuted)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.blush, in: Capsule())
            }.buttonStyle(.plain)
            Button { store.trashTask(task.id) } label: {
                Label("Delete", systemImage: "trash")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkMuted)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.blush, in: Capsule())
            }.buttonStyle(.plain)
        }
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
