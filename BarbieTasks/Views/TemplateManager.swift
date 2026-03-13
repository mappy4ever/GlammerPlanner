import SwiftUI

// MARK: - TemplateManagerView

struct TemplateManagerView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var newName = ""
    @State private var newTitle = ""
    @State private var deleteConfirmId: UUID?
    @FocusState private var focusedField: Field?

    private enum Field { case name, title }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().foregroundStyle(Color.petal)

            if store.templates.isEmpty {
                emptyState
            } else {
                templateList
            }

            Divider().foregroundStyle(Color.petal)
            newTemplateForm
        }
        .frame(width: 520, height: 540)
        .background(Color.blush)
        .alert("Delete Template?", isPresented: .init(
            get: { deleteConfirmId != nil },
            set: { if !$0 { deleteConfirmId = nil } }
        )) {
            Button("Cancel", role: .cancel) { deleteConfirmId = nil }
            Button("Delete", role: .destructive) {
                if let id = deleteConfirmId {
                    withAnimation(.easeOut(duration: 0.2)) {
                        store.deleteTemplate(id)
                    }
                    deleteConfirmId = nil
                }
            }
        } message: {
            Text("This template will be permanently removed.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Templates")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkPrimary)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.inkMuted)
            }
            .buttonStyle(.plain)
            .help("Close")
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 16)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            BarbieIcon.EmptyState(systemName: "doc.on.doc", size: 36)
            Text("No templates yet")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkSecondary)
            Text("Save a task as a template to get started")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Template List

    private var templateList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(store.templates) { template in
                    templateCard(template)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }

    private func templateCard(_ template: TaskTemplate) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkPrimary)
                        .lineLimit(1)

                    if template.title != template.name {
                        Text(template.title)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.inkSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                priorityBadge(template.priority)
            }

            HStack(spacing: 6) {
                if let projectId = template.projectId,
                   let project = store.projects.first(where: { $0.id == projectId }) {
                    HStack(spacing: 4) {
                        Circle().fill(project.color).frame(width: 6, height: 6)
                        Text(project.title)
                    }
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkSecondary)
                    .lineLimit(1)
                }

                if !template.subtasks.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "checklist")
                            .font(.system(size: 9))
                        Text("\(template.subtasks.count) subtask\(template.subtasks.count == 1 ? "" : "s")")
                    }
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkMuted)
                }

                tagPills(for: template)

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                Spacer()

                Button { deleteConfirmId = template.id } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.inkMuted)
                }
                .buttonStyle(.plain)
                .help("Delete template")

                Button("Use Template") {
                    store.createFromTemplate(template.id)
                    dismiss()
                }
                .buttonStyle(ChicButtonStyle())
                .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
        }
        .padding(14)
        .background(Color.blushMid, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.petal, lineWidth: 1))
    }

    @ViewBuilder
    private func priorityBadge(_ priority: BarbieTask.Priority) -> some View {
        if priority != .none {
            HStack(spacing: 3) {
                Image(systemName: priority.symbol)
                    .font(.system(size: 9, weight: .bold))
                Text(priority.label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(priorityColor(priority), in: Capsule())
        }
    }

    @ViewBuilder
    private func tagPills(for template: TaskTemplate) -> some View {
        let matchedTags = template.tagIds.compactMap { tagId in
            store.tags.first { $0.id == tagId }
        }
        ForEach(matchedTags.prefix(3)) { tag in
            Text(tag.name)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(tag.color, in: Capsule())
        }
        if matchedTags.count > 3 {
            Text("+\(matchedTags.count - 3)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkMuted)
        }
    }

    private func priorityColor(_ p: BarbieTask.Priority) -> Color {
        switch p {
        case .none: .petal
        case .low: .priLow
        case .medium: .priMed
        case .high: .priHigh
        }
    }

    // MARK: - New Template Form

    private var newTemplateForm: some View {
        VStack(spacing: 10) {
            Text("New Template")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                TextField("Template name", text: $newName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blush, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.petal, lineWidth: 1))
                    .focused($focusedField, equals: .name)
                    .onSubmit { focusedField = .title }

                TextField("Task title", text: $newTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blush, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.petal, lineWidth: 1))
                    .focused($focusedField, equals: .title)
                    .onSubmit { createTemplate() }
            }

            HStack(spacing: 10) {
                Spacer()
                Button("Create") { createTemplate() }
                    .buttonStyle(ChicButtonStyle())
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty
                              || newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private func createTemplate() {
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !trimmedTitle.isEmpty else { return }

        let template = TaskTemplate(name: trimmedName, title: trimmedTitle)
        withAnimation(.easeOut(duration: 0.2)) {
            store.addTemplate(template)
        }
        newName = ""
        newTitle = ""
        focusedField = .name
    }
}

// MARK: - SaveAsTemplateSheet

struct SaveAsTemplateSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    let taskId: UUID

    @State private var templateName = ""
    @FocusState private var isFocused: Bool

    private var task: BarbieTask? {
        store.tasks.first { $0.id == taskId }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Save as Template")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkPrimary)
                .padding(.top, 24)
                .padding(.bottom, 20)

            if let task {
                VStack(spacing: 16) {
                    TextField("Template name", text: $templateName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blush, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.petal, lineWidth: 1.5))
                        .focused($isFocused)
                        .onSubmit { save() }

                    // Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WILL SAVE")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.inkMuted)

                        HStack(spacing: 10) {
                            previewItem(icon: "text.quote", label: task.title)

                            if task.priority != .none {
                                previewItem(
                                    icon: task.priority.symbol,
                                    label: task.priority.label,
                                    color: previewPriorityColor(task.priority)
                                )
                            }
                        }

                        HStack(spacing: 10) {
                            if !task.subtasks.isEmpty {
                                previewItem(
                                    icon: "checklist",
                                    label: "\(task.subtasks.count) subtask\(task.subtasks.count == 1 ? "" : "s")"
                                )
                            }

                            if let projectId = task.projectId,
                               let project = store.projects.first(where: { $0.id == projectId }) {
                                previewItem(icon: "folder", label: project.title)
                            }

                            if !task.tagIds.isEmpty {
                                previewItem(icon: "tag", label: "\(task.tagIds.count) tag\(task.tagIds.count == 1 ? "" : "s")")
                            }
                        }

                        if task.recurrence != nil {
                            previewItem(icon: "repeat", label: "Recurrence rule")
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blushMid, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.petalLight, lineWidth: 1))
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            HStack(spacing: 10) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(ChicSecondaryButtonStyle())
                Button("Save") { save() }
                    .buttonStyle(ChicButtonStyle())
                    .disabled(templateName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.bottom, 24)
        }
        .frame(width: 360, height: 340)
        .onAppear {
            if let task {
                templateName = task.title
            }
            isFocused = true
        }
    }

    private func previewItem(icon: String, label: String, color: Color = .inkSecondary) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(label)
                .lineLimit(1)
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundStyle(color)
    }

    private func previewPriorityColor(_ p: BarbieTask.Priority) -> Color {
        switch p {
        case .none: .inkSecondary
        case .low: .priLow
        case .medium: .priMed
        case .high: .priHigh
        }
    }

    private func save() {
        let trimmed = templateName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.saveTaskAsTemplate(taskId, name: trimmed)
        dismiss()
    }
}
