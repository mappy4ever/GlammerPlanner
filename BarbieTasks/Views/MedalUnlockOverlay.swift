import SwiftUI

// MARK: - Medal Unlock Toast (non-intrusive, clickable)

struct MedalUnlockOverlay: View {
    @Environment(Store.self) private var store
    @State private var showToast = false
    @State private var toastScale: CGFloat = 0.8
    @State private var shimmerOffset: CGFloat = -300
    @State private var glowPulse = false

    private var currentMedal: MedalDefinition? {
        store.pendingMedalUnlocks.first?.definition
    }

    var body: some View {
        if store.showMedalUnlock, let medal = currentMedal {
            VStack {
                // Toast slides down from top
                HStack(spacing: 12) {
                    // Medal icon with tier glow
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: medal.tier.colors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: medal.tier.glowColor.opacity(glowPulse ? 0.7 : 0.3), radius: glowPulse ? 12 : 6)

                        // Shimmer sweep
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.5), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .offset(x: shimmerOffset)
                            .mask(Circle().frame(width: 44, height: 44))

                        Image(systemName: medal.icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(medal.tier.glowColor)
                            Text("MEDAL UNLOCKED")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .tracking(1)
                                .foregroundStyle(medal.tier.glowColor)
                        }

                        Text(medal.title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.inkPrimary)

                        Text(medal.description)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.inkSecondary)
                    }

                    Spacer()

                    // Tier badge
                    Text(medal.tier.label)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(
                            LinearGradient(
                                colors: medal.tier.colors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(medal.tier.glowColor.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(medal.tier.glowColor.opacity(0.3), lineWidth: 1)
                                )
                        )

                    // View button
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.inkMuted)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            medal.tier.glowColor.opacity(0.4),
                                            medal.tier.glowColor.opacity(0.1),
                                            medal.tier.glowColor.opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: medal.tier.glowColor.opacity(0.25), radius: 16, y: 4)
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                )
                .scaleEffect(toastScale)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .onTapGesture {
                    // Navigate to stats/medals view
                    store.selectedView = .stats
                    dismissToast()
                }
                .onHover { hovering in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        toastScale = hovering ? 1.02 : 1.0
                    }
                }

                Spacer()
            }
            .transition(
                .asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9, anchor: .top)),
                    removal: .move(edge: .top).combined(with: .opacity)
                )
            )
            .onAppear { animateIn() }
        }
    }

    private func animateIn() {
        // Toast pop in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
            showToast = true
            toastScale = 1.0
        }

        // Shimmer sweep
        withAnimation(.smooth(duration: 1.0).delay(0.3)) {
            shimmerOffset = 300
        }

        // Repeat shimmer
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            shimmerOffset = -300
            withAnimation(.smooth(duration: 0.8)) {
                shimmerOffset = 300
            }
        }

        // Glow pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }

        // Auto-dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak store] in
            guard store?.showMedalUnlock == true else { return }
            dismissToast()
        }
    }

    private func dismissToast() {
        withAnimation(.smooth(duration: 0.3)) {
            toastScale = 0.9
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.smooth(duration: 0.3)) {
                store.showMedalUnlock = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if !store.pendingMedalUnlocks.isEmpty {
                store.pendingMedalUnlocks.removeFirst()
            }
            showToast = false
            toastScale = 0.8
            shimmerOffset = -300
            glowPulse = false

            // Show next medal if there are more
            if !store.pendingMedalUnlocks.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                        store.showMedalUnlock = true
                    }
                }
            }
        }
    }
}
