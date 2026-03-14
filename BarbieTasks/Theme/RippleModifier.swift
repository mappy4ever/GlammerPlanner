import SwiftUI

/// Applies a Metal shader ripple effect that plays on appear
struct RippleModifier: ViewModifier {
    @State private var startTime: Date?
    @State private var done = false

    func body(content: Content) -> some View {
        if done {
            // Animation finished — static view, no more frame requests
            content
        } else {
            TimelineView(.animation) { timeline in
                let elapsed = startTime.map { Float(timeline.date.timeIntervalSince($0)) } ?? 0
                let t = min(elapsed, 2.0)
                // Amplitude decays from 8 → 0 over 2 seconds
                let amp = max(0, 8.0 * (1.0 - t / 2.0))

                content
                    .distortionEffect(
                        ShaderLibrary.ripple(
                            .float(t),
                            .float2(80, 22),    // origin — left side of banner
                            .float(amp),
                            .float(18.0),       // frequency — wave density
                            .float(1.2)         // decay rate
                        ),
                        maxSampleOffset: CGSize(width: 20, height: 20)
                    )
                    .onChange(of: elapsed > 2.0) {
                        if elapsed > 2.0 { done = true }
                    }
            }
            .onAppear { startTime = .now }
        }
    }
}

extension View {
    func rippleEffect() -> some View {
        modifier(RippleModifier())
    }
}
