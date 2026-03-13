import SwiftUI

struct TagEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedColor = Color.projectColors.first!
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text("New Tag")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkPrimary)
                .padding(.top, 24).padding(.bottom, 20)

            TextField("Tag name", text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Color.blush, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.petal, lineWidth: 1.5))
                .focused($isFocused)
                .onSubmit { create() }
                .padding(.horizontal, 24)

            Text("Color")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 8)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 10), count: 5), spacing: 10) {
                ForEach(Color.projectColors, id: \.self) { hex in
                    Button { withAnimation(.easeOut(duration: 0.15)) { selectedColor = hex } } label: {
                        ZStack {
                            Circle().fill(Color(hex: hex)).frame(width: 30, height: 30)
                            if selectedColor == hex {
                                Circle().stroke(Color.inkPrimary, lineWidth: 2.5).frame(width: 36, height: 36)
                            }
                        }
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            HStack(spacing: 10) {
                Button("Cancel") { dismiss() }.buttonStyle(ChicSecondaryButtonStyle())
                Button("Create") { create() }.buttonStyle(ChicButtonStyle())
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.bottom, 24)
        }
        .frame(width: 320, height: 340)
        .onAppear { isFocused = true }
    }

    private func create() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.addTag(name: trimmed, colorHex: selectedColor)
        dismiss()
    }
}
