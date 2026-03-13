import SwiftUI

struct RoutinesView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showNewRoutine = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Routines")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkPrimary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.inkMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            if store.routines.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        // Today's routines first
                        let todayRoutines = store.routines.filter(\.isForToday)
                        if !todayRoutines.isEmpty {
                            sectionHeader("Today's Routines")
                            ForEach(todayRoutines) { routine in
                                RoutineCard(routine: routine, isToday: true)
                            }
                        }

                        // All other routines
                        let otherRoutines = store.routines.filter { !$0.isForToday }
                        if !otherRoutines.isEmpty {
                            sectionHeader("All Routines")
                            ForEach(otherRoutines) { routine in
                                RoutineCard(routine: routine, isToday: false)
                            }
                        }
                    }
                    .padding(16)
                }
            }

            Divider()

            // Add routine button
            Button { showNewRoutine = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("New Routine")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.barbiePink, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 12)
        }
        .frame(minWidth: 480, maxWidth: 480, minHeight: 400, maxHeight: 600)
        .background(Color.blush)
        .sheet(isPresented: $showNewRoutine) {
            RoutineEditorView()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            BarbieIcon.EmptyState(systemName: "repeat.circle", size: 36)
            Text("No Routines Yet")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkSecondary)
            Text("Create routines for tasks you repeat on certain days.\nActivate them with one tap!")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkMuted)
            Spacer()
        }
        .padding(.top, 4)
    }
}

// MARK: - Routine Card

private struct RoutineCard: View {
    @Environment(Store.self) private var store
    let routine: Routine
    let isToday: Bool
    @State private var isHovered = false
    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(routine.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkPrimary)

                    Text(routine.daysSummary)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.barbiePink)
                }

                Spacer()

                HStack(spacing: 6) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                            store.activateRoutine(routine.id)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 12))
                            Text("Add to Today")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            isToday
                                ? Color.barbiePink
                                : Color.barbieRose,
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)

                    Menu {
                        Button("Edit") { showEdit = true }
                        Divider()
                        Button("Delete", role: .destructive) { showDeleteConfirm = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.inkMuted)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 20)
                }
            }

            // Task list preview
            if !routine.tasks.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(routine.tasks.prefix(5)) { task in
                        HStack(spacing: 6) {
                            Circle()
                                .stroke(Color.petal, lineWidth: 1.5)
                                .frame(width: 12, height: 12)
                            Text(task.title)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.inkSecondary)
                                .lineLimit(1)
                        }
                    }
                    if routine.tasks.count > 5 {
                        Text("+\(routine.tasks.count - 5) more")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.inkMuted)
                            .padding(.leading, 18)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.blushMid.opacity(isHovered ? 1 : 0.6), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isToday ? Color.barbiePink.opacity(0.3) : Color.petal.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: isHovered ? Color.barbiePink.opacity(0.08) : .clear, radius: 8, y: 2)
        .onHover { isHovered = $0 }
        .animation(.smooth(duration: 0.2), value: isHovered)
        .sheet(isPresented: $showEdit) {
            RoutineEditorView(existingRoutine: routine)
        }
        .confirmationDialog("Delete \(routine.name)?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                withAnimation { store.deleteRoutine(routine.id) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This routine will be permanently deleted.")
        }
    }
}

// MARK: - Routine Editor

struct RoutineEditorView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    var existingRoutine: Routine?

    @State private var name: String = ""
    @State private var selectedDays: Set<Int> = []
    @State private var tasks: [RoutineTask] = []
    @State private var newTaskTitle: String = ""

    private let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 0) {
            editorHeader
            Divider()
            editorContent
            Divider()
            editorFooter
        }
        .frame(minWidth: 440, maxWidth: 440, minHeight: 400, maxHeight: 550)
        .background(Color.blush)
        .onAppear {
            if let r = existingRoutine {
                name = r.name
                selectedDays = r.days
                tasks = r.tasks
            }
        }
    }

    private var editorHeader: some View {
        HStack {
            Text(existingRoutine == nil ? "New Routine" : "Edit Routine")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkPrimary)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.inkMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var editorContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                nameSection
                daysSection
                tasksSection
            }
            .padding(20)
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Routine Name")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkMuted)
            TextField("e.g., Monday Morning", text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .padding(10)
                .background(Color.blushMid, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var daysSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Repeat On")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkMuted)

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    let weekday = i == 0 ? 1 : i + 1
                    Button {
                        if selectedDays.contains(weekday) {
                            selectedDays.remove(weekday)
                        } else {
                            selectedDays.insert(weekday)
                        }
                    } label: {
                        Text(dayLabels[i])
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .frame(width: 40, height: 32)
                            .background(
                                selectedDays.contains(weekday) ? Color.barbiePink : Color.blushMid,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .foregroundStyle(
                                selectedDays.contains(weekday) ? .white : Color.inkSecondary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                Button("Weekdays") { selectedDays = [2, 3, 4, 5, 6] }
                Button("Weekends") { selectedDays = [1, 7] }
                Button("Every Day") { selectedDays = Set(1...7) }
            }
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.barbiePink)
            .buttonStyle(.plain)
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tasks (\(tasks.count))")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkMuted)

            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                HStack(spacing: 8) {
                    Circle()
                        .stroke(Color.petal, lineWidth: 1.5)
                        .frame(width: 14, height: 14)
                    Text(task.title)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.inkPrimary)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        withAnimation(.smooth(duration: 0.2)) { _ = tasks.remove(at: index) }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.inkMuted.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
            }

            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.inkMuted)
                TextField("Add task to routine...", text: $newTaskTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .onSubmit { addTask() }
                if !newTaskTitle.isEmpty {
                    Button { addTask() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.barbiePink)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var editorFooter: some View {
        HStack {
            Spacer()
            Button("Cancel") { dismiss() }
                .buttonStyle(ChicSecondaryButtonStyle())
            Button(existingRoutine == nil ? "Create Routine" : "Save Changes") {
                saveRoutine()
            }
            .buttonStyle(ChicButtonStyle())
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || tasks.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            tasks.append(RoutineTask(title: title))
            newTaskTitle = ""
        }
    }

    private func saveRoutine() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !tasks.isEmpty else { return }

        if let existing = existingRoutine {
            store.updateRoutine(existing.id) { r in
                r.name = trimmedName
                r.days = selectedDays
                r.tasks = tasks
            }
        } else {
            var routine = Routine(name: trimmedName)
            routine.days = selectedDays
            routine.tasks = tasks
            store.addRoutine(routine)
        }
        dismiss()
    }
}
