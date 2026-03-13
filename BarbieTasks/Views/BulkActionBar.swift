import SwiftUI

struct BulkActionBar: View {
    @Environment(Store.self) private var store
    @State private var showBulkTrashConfirm = false

    var body: some View {
        HStack(spacing: 16) {
            Text("\(store.selectedTaskIds.count) selected")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Divider().frame(height: 18).overlay(Color.white.opacity(0.3))

            Button { withAnimation { store.bulkComplete() } } label: {
                Label("Complete", systemImage: "checkmark.circle")
            }

            Menu {
                ForEach(BarbieTask.Priority.allCases) { p in
                    Button(p.label) { store.bulkSetPriority(p) }
                }
            } label: {
                Label("Priority", systemImage: "arrow.up.arrow.down")
            }

            if !store.projects.isEmpty {
                Menu {
                    Button("Inbox") { store.bulkMoveToProject(nil) }
                    Divider()
                    ForEach(store.projects) { p in
                        Button(p.title) { store.bulkMoveToProject(p.id) }
                    }
                } label: {
                    Label("Move", systemImage: "folder")
                }
            }

            Button(role: .destructive) { showBulkTrashConfirm = true } label: {
                Label("Trash", systemImage: "trash")
            }

            Spacer()

            Button { store.selectedTaskIds = [] } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundStyle(.white)
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.inkPrimary, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.2), radius: 16, y: 4)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .alert("Move \(store.selectedTaskIds.count) tasks to Trash?", isPresented: $showBulkTrashConfirm) {
            Button("Trash", role: .destructive) {
                withAnimation { store.bulkTrash() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can restore trashed tasks later.")
        }
    }
}
