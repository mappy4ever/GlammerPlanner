import SwiftUI
import AppKit

struct ProgressRingView: View {
    @Environment(Store.self) private var store
    @State private var animatedPct: Double = 0
    @State private var ringGlow: Double = 0
    @State private var completedPulse: CGFloat = 1.0
    @State private var showCheckmark = false
    @State private var previousDone: Int = -1

    private var total: Int { store.currentViewTasks.count }
    private var done: Int { store.currentViewTasks.filter(\.isDone).count }
    private var pct: Double { total > 0 ? Double(done) / Double(total) : 0 }
    private var isComplete: Bool { total > 0 && done == total }

    var body: some View {
        ZStack {
            // Track ring
            Circle()
                .stroke(Color.petalLight, lineWidth: 7)

            // Progress ring — gradient stroke
            Circle()
                .trim(from: 0, to: animatedPct)
                .stroke(
                    AngularGradient(
                        colors: ThemeManager.shared.current == .classic
                            ? Color.classicRainbow + [Color.classicRainbow[0]]
                            : [Color.barbiePink, Color.barbieDeep, Color.barbiePink],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Glow ring (pulses on completion)
            if ringGlow > 0 {
                Circle()
                    .stroke(Color.barbiePink.opacity(ringGlow * 0.5), lineWidth: 12)
                    .blur(radius: 6)
                    .scaleEffect(completedPulse)
            }

            // Center content
            if isComplete && showCheckmark {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.barbiePink)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            } else {
                Text("\(Int(animatedPct * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkSecondary)
            }
        }
        .frame(width: 50, height: 50)
        .scaleEffect(completedPulse)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(done) of \(total) tasks completed, \(Int(pct * 100)) percent")
        .onAppear {
            animatedPct = pct
            previousDone = done
        }
        .onChange(of: done) { oldDone, newDone in
            let targetPct = pct

            // Smooth ring-closing animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animatedPct = targetPct
            }

            // Ring just completed — celebrate!
            if total > 0 && newDone == total && oldDone < total {
                ringCompleted()
            } else if newDone > oldDone {
                // Progressed but not complete — small pulse
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                    completedPulse = 1.08
                }
                withAnimation(.smooth(duration: 0.3).delay(0.2)) {
                    completedPulse = 1.0
                }
            }

            previousDone = newDone
        }
        .onChange(of: total) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animatedPct = pct
            }
        }
    }

    private func ringCompleted() {
        // Play system sound
        NSSound(named: "Glass")?.play()

        // Glow + pulse animation sequence
        withAnimation(.easeIn(duration: 0.3)) {
            ringGlow = 1.0
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.4)) {
            completedPulse = 1.2
            showCheckmark = true
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.15)) {
            completedPulse = 1.0
        }

        // Pulse glow out
        withAnimation(.easeOut(duration: 1.0).delay(0.8)) {
            ringGlow = 0
        }

        // Hide checkmark after a moment, show percentage again
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.smooth(duration: 0.3)) {
                showCheckmark = false
            }
        }
    }
}
