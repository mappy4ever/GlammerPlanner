import SwiftUI

struct FilterEditorView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    var existingFilter: SavedFilter?

    @State private var name = ""
    @State private var selectedColor = "#D4577A"
    @State private var selectedPriorities: Set<Int> = []
    @State private var selectedProjectIds: Set<UUID> = []
    @State private var selectedTagIds: Set<UUID> = []
    @State private var dueDateRange: SavedFilter.FilterCriteria.DateRange?
    @FocusState private var isFocused: Bool

    private var isEditing: Bool { existingFilter != nil }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text(isEditing ? "Edit Filter" : "New Filter")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkPrimary)
                .padding(.top, 24)
                .padding(.bottom, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Name field
                    TextField("Filter name", text: $name)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blush, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.petal, lineWidth: 1.5)
                        )
                        .focused($isFocused)

                    // Color picker
                    sectionLabel("Color")

                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 10), count: 5), spacing: 10) {
                        ForEach(Color.projectColors, id: \.self) { hex in
                            Button {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    selectedColor = hex
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 30, height: 30)

                                    if selectedColor == hex {
                                        Circle()
                                            .stroke(Color.inkPrimary, lineWidth: 2.5)
                                            .frame(width: 36, height: 36)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Priority
                    sectionLabel("Priority")

                    HStack(spacing: 6) {
                        ForEach(BarbieTask.Priority.allCases) { p in
                            Button {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    if selectedPriorities.contains(p.rawValue) {
                                        selectedPriorities.remove(p.rawValue)
                                    } else {
                                        selectedPriorities.insert(p.rawValue)
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: selectedPriorities.contains(p.rawValue) ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 12))
                                    Text(p.label)
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(
                                    selectedPriorities.contains(p.rawValue) ? priorityColor(p).opacity(0.15) : Color.blush,
                                    in: Capsule()
                                )
                                .foregroundStyle(
                                    selectedPriorities.contains(p.rawValue) ? priorityColor(p) : Color.inkSecondary
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Projects
                    if !store.projects.isEmpty {
                        sectionLabel("Projects")

                        FlowLayout(spacing: 6) {
                            ForEach(store.projects) { project in
                                Button {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        if selectedProjectIds.contains(project.id) {
                                            selectedProjectIds.remove(project.id)
                                        } else {
                                            selectedProjectIds.insert(project.id)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(project.color)
                                            .frame(width: 8, height: 8)
                                        Text(project.title)
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        selectedProjectIds.contains(project.id) ? project.color.opacity(0.15) : Color.blush,
                                        in: Capsule()
                                    )
                                    .foregroundStyle(
                                        selectedProjectIds.contains(project.id) ? project.color : Color.inkSecondary
                                    )
                                    .overlay(
                                        Capsule().stroke(
                                            selectedProjectIds.contains(project.id) ? project.color.opacity(0.4) : Color.clear,
                                            lineWidth: 1
                                        )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Tags
                    if !store.tags.isEmpty {
                        sectionLabel("Tags")

                        FlowLayout(spacing: 6) {
                            ForEach(store.tags) { tag in
                                Button {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        if selectedTagIds.contains(tag.id) {
                                            selectedTagIds.remove(tag.id)
                                        } else {
                                            selectedTagIds.insert(tag.id)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(tag.color)
                                            .frame(width: 8, height: 8)
                                        Text(tag.name)
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        selectedTagIds.contains(tag.id) ? tag.color.opacity(0.15) : Color.blush,
                                        in: Capsule()
                                    )
                                    .foregroundStyle(
                                        selectedTagIds.contains(tag.id) ? tag.color : Color.inkSecondary
                                    )
                                    .overlay(
                                        Capsule().stroke(
                                            selectedTagIds.contains(tag.id) ? tag.color.opacity(0.4) : Color.clear,
                                            lineWidth: 1
                                        )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Due date range
                    sectionLabel("Due Date")

                    HStack(spacing: 6) {
                        ForEach(SavedFilter.FilterCriteria.DateRange.allCases, id: \.self) { range in
                            Button {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    dueDateRange = dueDateRange == range ? nil : range
                                }
                            } label: {
                                Text(range.label)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        dueDateRange == range ? Color.barbiePink.opacity(0.15) : Color.blush,
                                        in: Capsule()
                                    )
                                    .foregroundStyle(
                                        dueDateRange == range ? Color.barbiePink : Color.inkSecondary
                                    )
                                    .overlay(
                                        Capsule().stroke(
                                            dueDateRange == range ? Color.barbiePink.opacity(0.4) : Color.clear,
                                            lineWidth: 1
                                        )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer(minLength: 12)

            // Buttons
            HStack(spacing: 10) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(ChicSecondaryButtonStyle())

                Button(isEditing ? "Save" : "Create Filter") {
                    saveFilter()
                }
                .buttonStyle(ChicButtonStyle())
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.bottom, 24)
        }
        .frame(width: 420, height: 480)
        .onAppear {
            isFocused = true
            if let filter = existingFilter {
                name = filter.name
                selectedColor = filter.colorHex
                selectedPriorities = filter.criteria.priorities
                selectedProjectIds = filter.criteria.projectIds
                selectedTagIds = filter.criteria.tagIds
                dueDateRange = filter.criteria.dueDateRange
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(Color.inkMuted)
    }

    private func priorityColor(_ p: BarbieTask.Priority) -> Color {
        switch p {
        case .none: return .petal
        case .low: return .priLow
        case .medium: return .priMed
        case .high: return .priHigh
        }
    }

    private func saveFilter() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let criteria = SavedFilter.FilterCriteria(
            priorities: selectedPriorities,
            projectIds: selectedProjectIds,
            tagIds: selectedTagIds,
            dueDateRange: dueDateRange
        )

        if let existing = existingFilter {
            store.updateSavedFilter(existing.id) { filter in
                filter.name = trimmed
                filter.colorHex = selectedColor
                filter.criteria = criteria
            }
        } else {
            let filter = SavedFilter(
                name: trimmed,
                colorHex: selectedColor,
                criteria: criteria
            )
            store.addSavedFilter(filter)
        }

        dismiss()
    }
}

// MARK: - Flow Layout

/// A simple flow layout that wraps items to new lines
private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private struct ArrangeResult {
        var positions: [CGPoint]
        var sizes: [CGSize]
        var size: CGSize
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> ArrangeResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            sizes.append(size)
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return ArrangeResult(
            positions: positions,
            sizes: sizes,
            size: CGSize(width: maxWidth, height: totalHeight)
        )
    }
}
