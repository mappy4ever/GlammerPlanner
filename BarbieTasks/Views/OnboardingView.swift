import SwiftUI

struct OnboardingView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    @State private var appeared = false

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            // Content area
            ZStack {
                stepView(for: 0)
                    .opacity(currentStep == 0 ? 1 : 0)
                    .offset(x: offset(for: 0))
                stepView(for: 1)
                    .opacity(currentStep == 1 ? 1 : 0)
                    .offset(x: offset(for: 1))
                stepView(for: 2)
                    .opacity(currentStep == 2 ? 1 : 0)
                    .offset(x: offset(for: 2))
                stepView(for: 3)
                    .opacity(currentStep == 3 ? 1 : 0)
                    .offset(x: offset(for: 3))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.35), value: currentStep)

            Divider()
                .overlay(Color.petal)

            // Bottom bar: dots + navigation
            HStack {
                // Back button
                Button {
                    currentStep -= 1
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back")
                    }
                }
                .buttonStyle(ChicSecondaryButtonStyle())
                .opacity(currentStep > 0 ? 1 : 0)
                .disabled(currentStep == 0)

                Spacer()

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        Circle()
                            .fill(i == currentStep ? Color.barbiePink : Color.petal)
                            .frame(width: 7, height: 7)
                            .scaleEffect(i == currentStep ? 1.15 : 1)
                            .animation(.easeOut(duration: 0.25), value: currentStep)
                    }
                }

                Spacer()

                // Next / Finish button
                if currentStep < totalSteps - 1 {
                    Button {
                        currentStep += 1
                    } label: {
                        HStack(spacing: 4) {
                            Text("Next")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                    .buttonStyle(ChicButtonStyle())
                } else {
                    Button("Start Slaying") {
                        settings.hasCompletedOnboarding = true
                        dismiss()
                    }
                    .buttonStyle(ChicButtonStyle())
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
        }
        .frame(width: 600, height: 440)
        .background(Color.blush)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7).delay(0.15)) {
                appeared = true
            }
        }
    }

    // MARK: - Offset

    private func offset(for step: Int) -> CGFloat {
        if step == currentStep { return 0 }
        return step < currentStep ? -40 : 40
    }

    // MARK: - Step Router

    @ViewBuilder
    private func stepView(for step: Int) -> some View {
        switch step {
        case 0: welcomeStep
        case 1: featuresStep
        case 2: shortcutsStep
        case 3: readyStep
        default: EmptyView()
        }
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Spacer()

            // App icon stand-in
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.barbiePink.opacity(0.12), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.barbiePink, Color.barbieDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.6)
            }

            VStack(spacing: 8) {
                Text("Glam Plan")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.barbiePink, Color.barbieDeep],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                Text("My Slay List")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.barbieRose)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
            }

            Text("Your chicest way to get things done.")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Color.inkSecondary)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 6)

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Step 2: Features

    private var featuresStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("What you can do")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkPrimary)

            VStack(spacing: 14) {
                featureRow(
                    icon: { AnyView(BarbieIcon.QuickAdd(size: 22)) },
                    title: "Quick Add",
                    subtitle: "Natural language task entry"
                )
                featureRow(
                    icon: { AnyView(BarbieIcon.Kanban(size: 22)) },
                    title: "Kanban Board",
                    subtitle: "Drag & drop board view"
                )
                featureRow(
                    icon: { AnyView(BarbieIcon.Timer(size: 22)) },
                    title: "Focus Timer",
                    subtitle: "Built-in focus timer"
                )
                featureRow(
                    icon: { AnyView(BarbieIcon.Stats(size: 22)) },
                    title: "Statistics",
                    subtitle: "Track your progress"
                )
            }
            .padding(.horizontal, 60)

            Spacer()
        }
    }

    private func featureRow(icon: () -> AnyView, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.blushMid)
                    .frame(width: 42, height: 42)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.petal, lineWidth: 1)
                    .frame(width: 42, height: 42)
                icon()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkPrimary)
                Text(subtitle)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Color.inkSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Step 3: Shortcuts

    private var shortcutsStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Keyboard shortcuts")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkPrimary)

            Text("Navigate at the speed of thought.")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(Color.inkSecondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                shortcutCard(keys: ["Cmd", "N"], label: "New Task")
                shortcutCard(keys: ["Cmd", "K"], label: "Command Palette")
                shortcutCard(keys: ["Ctrl", "Space"], label: "Quick Add (anywhere)")
                shortcutCard(keys: ["Cmd", "1-4"], label: "Switch views")
            }
            .padding(.horizontal, 50)

            Spacer()
        }
    }

    private func shortcutCard(keys: [String], label: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 3) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.blush)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(Color.petal, lineWidth: 1)
                        )
                        .foregroundStyle(Color.inkPrimary)
                }
            }
            Text(label)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.blushMid)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.petalLight, lineWidth: 1)
        )
    }

    // MARK: - Step 4: Ready

    private var readyStep: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.barbiePink.opacity(0.10), Color.clear],
                            center: .center,
                            startRadius: 5,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.barbiePink, Color.barbieRose, Color.roseGold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("You're all set, queen.")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkPrimary)

                Text("Your tasks, your way. Organized and on point.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(Color.inkSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    OnboardingView()
        .environment(AppSettings())
}
