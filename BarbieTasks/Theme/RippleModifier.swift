import SwiftUI

/// Applies a Metal shader ripple effect that triggers on appear
struct RippleModifier: ViewModifier {
    var trigger: UUID
    @State private var time: CGFloat = 0
    @State private var animating = false

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: RippleData(), trigger: trigger) { view, data in
                view
                    .distortionEffect(
                        ShaderLibrary.ripple(
                            .float(data.time),
                            .float2(150, 20),   // origin — center-left of banner
                            .float(data.amplitude),
                            .float(data.frequency),
                            .float(data.decay)
                        ),
                        maxSampleOffset: CGSize(width: 12, height: 12)
                    )
            } keyframes: { _ in
                KeyframeTrack(\.time) {
                    CubicKeyframe(0.0, duration: 0)
                    CubicKeyframe(1.2, duration: 1.2)
                }
                KeyframeTrack(\.amplitude) {
                    CubicKeyframe(4.0, duration: 0)
                    CubicKeyframe(3.0, duration: 0.4)
                    CubicKeyframe(0.0, duration: 0.8)
                }
                KeyframeTrack(\.frequency) {
                    CubicKeyframe(25.0, duration: 0)
                    CubicKeyframe(18.0, duration: 1.2)
                }
                KeyframeTrack(\.decay) {
                    CubicKeyframe(1.2, duration: 0)
                    CubicKeyframe(2.0, duration: 1.2)
                }
            }
    }
}

private struct RippleData {
    var time: CGFloat = 0
    var amplitude: CGFloat = 0
    var frequency: CGFloat = 0
    var decay: CGFloat = 0
}

extension View {
    func rippleEffect(trigger: UUID) -> some View {
        modifier(RippleModifier(trigger: trigger))
    }
}
