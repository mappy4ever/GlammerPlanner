import SwiftUI

// MARK: - Celebration Overlay

struct CelebrationOverlay: View {
    @Environment(Store.self) private var store
    @Environment(AppSettings.self) private var settings

    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 12
    @State private var cardScale: CGFloat = 0.6
    @State private var cardOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200

    private var reduced: Bool { settings.reduceAnimations }

    var body: some View {
        if let quote = store.celebrationQuote {
            ZStack {
                if reduced {
                    // Reduced motion: simple text with fade only
                    Text(quote.text)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 28)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.barbiePink, Color.barbieDeep],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .opacity(cardOpacity)
                        .frame(maxWidth: 340)
                        .accessibilityLabel(quote.text)
                        .accessibilityAddTraits(.isStaticText)
                        .transition(.opacity)
                } else {
                    // Full celebration with glow, shimmer, and spring
                    // Soft radial glow behind card
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.barbiePink.opacity(0.25), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .opacity(glowOpacity)
                        .blur(radius: 30)

                    // Main card
                    VStack(spacing: 0) {
                        // Quote text with fade-slide
                        Text(quote.text)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .opacity(textOpacity)
                            .offset(y: textOffset)
                            .lineSpacing(4)
                            .accessibilityLabel(quote.text)
                            .accessibilityAddTraits(.isStaticText)
                    }
                    .padding(.horizontal, 36)
                    .padding(.vertical, 28)
                    .background(
                        ZStack {
                            // Base gradient
                            RoundedRectangle(cornerRadius: 22)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.barbiePink, Color.barbieDeep, Color(hex: "#9B3A6A")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            // Shimmer sweep
                            RoundedRectangle(cornerRadius: 22)
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.15), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: shimmerOffset)
                                .mask(RoundedRectangle(cornerRadius: 22))
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: Color.barbiePink.opacity(0.4), radius: 30, y: 10)
                    .shadow(color: Color.barbieDeep.opacity(0.2), radius: 60, y: 20)
                    .scaleEffect(cardScale)
                    .opacity(cardOpacity)
                    .frame(maxWidth: 340)
                }
            }
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.3)) {
                    store.celebrationQuote = nil
                    store.showConfetti = false
                }
            }
            .onAppear { animateIn() }
        }
    }

    private func animateIn() {
        if reduced {
            // Simple opacity fade — no spring, no scale, no shimmer
            cardScale = 1.0
            textOffset = 0
            withAnimation(.easeIn(duration: 0.3)) {
                cardOpacity = 1.0
                textOpacity = 1.0
            }
            return
        }

        // Card entrance — spring pop with satisfying bounce
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
            cardScale = 1.0
            cardOpacity = 1.0
        }

        // Glow
        withAnimation(.easeOut(duration: 0.6)) {
            glowOpacity = 0.8
        }

        // Text — smooth reveal after card lands
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            textOpacity = 1.0
            textOffset = 0
        }

        // Shimmer sweep across card
        withAnimation(.easeInOut(duration: 0.8).delay(0.5)) {
            shimmerOffset = 200
        }

        // Second shimmer
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            shimmerOffset = -200
            withAnimation(.easeInOut(duration: 0.8)) {
                shimmerOffset = 200
            }
        }
    }
}

// MARK: - Confetti

struct ConfettiView: View {
    @Environment(AppSettings.self) private var settings
    @State private var particles: [ConfettiParticle] = []

    private static let colors: [Color] = [
        .barbiePink, .barbieRose, Color(hex: "#F48FB1"),
        Color(hex: "#CE93D8"), Color(hex: "#FFD54F"), Color(hex: "#FF80AB"),
        .white, Color(hex: "#E1BEE7"), Color(hex: "#F8BBD0"),
        .gold, Color(hex: "#FFAB91"), Color(hex: "#B39DDB"),
    ]

    var body: some View {
        if settings.reduceAnimations {
            // Simple sparkle fallback
            SimpleSparkleView()
        } else {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    for p in particles {
                        drawParticle(p, now: now, in: &context, size: size)
                    }
                }
            }
            .ignoresSafeArea()
            .onAppear { spawnParticles() }
        }
    }

    private func drawParticle(_ p: ConfettiParticle, now: TimeInterval, in context: inout GraphicsContext, size: CGSize) {
        let age = now - p.startTime
        guard age > 0, age < p.lifetime else { return }

        let progress = age / p.lifetime
        let x = p.x * size.width + p.vx * age
        let y = p.vy * age + 150 * age * age // gravity
        let opacity = 1.0 - progress * progress * progress // slower fade
        let rotation = Angle.degrees(p.spin * age * 200)

        context.opacity = opacity

        // Wobble for flutter effect
        let wobble = sin(age * p.wobbleSpeed) * p.wobbleAmount

        context.translateBy(x: x + wobble, y: y)
        context.rotate(by: rotation)

        switch p.shape {
        case .rect:
            let w = p.size
            let h = p.size * (0.4 + 0.6 * abs(cos(age * 4)))
            context.fill(
                Path(CGRect(x: -w/2, y: -h/2, width: w, height: h)),
                with: .color(p.color)
            )

        case .circle:
            let r = p.size * 0.5
            context.fill(
                Path(ellipseIn: CGRect(x: -r, y: -r, width: r*2, height: r*2)),
                with: .color(p.color)
            )

        case .heart:
            let s = p.size * 0.6
            context.fill(heartPath(size: s), with: .color(p.color))

        case .star:
            let s = p.size * 0.5
            context.fill(starPath(size: s), with: .color(p.color))

        case .diamond:
            let s = p.size * 0.5
            let path = Path { path in
                path.move(to: CGPoint(x: 0, y: -s))
                path.addLine(to: CGPoint(x: s * 0.6, y: 0))
                path.addLine(to: CGPoint(x: 0, y: s))
                path.addLine(to: CGPoint(x: -s * 0.6, y: 0))
                path.closeSubpath()
            }
            context.fill(path, with: .color(p.color))
        }

        context.rotate(by: -rotation)
        context.translateBy(x: -(x + wobble), y: -y)
    }

    private func heartPath(size: CGFloat) -> Path {
        Path { path in
            let s = size
            path.move(to: CGPoint(x: 0, y: s * 0.3))
            path.addCurve(
                to: CGPoint(x: 0, y: -s * 0.4),
                control1: CGPoint(x: -s, y: -s * 0.2),
                control2: CGPoint(x: -s * 0.5, y: -s)
            )
            path.addCurve(
                to: CGPoint(x: 0, y: s * 0.3),
                control1: CGPoint(x: s * 0.5, y: -s),
                control2: CGPoint(x: s, y: -s * 0.2)
            )
            path.closeSubpath()
        }
    }

    private func starPath(size: CGFloat) -> Path {
        Path { path in
            let points = 5
            let outerRadius = size
            let innerRadius = size * 0.4
            for i in 0..<points * 2 {
                let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
                let angle = Double(i) * .pi / Double(points) - .pi / 2
                let point = CGPoint(
                    x: cos(angle) * radius,
                    y: sin(angle) * radius
                )
                if i == 0 { path.move(to: point) }
                else { path.addLine(to: point) }
            }
            path.closeSubpath()
        }
    }

    private func spawnParticles() {
        let count = 60
        let now = Date.timeIntervalSinceReferenceDate
        particles = (0..<count).map { i in
            let shapes: [ConfettiShape] = [.rect, .rect, .circle, .heart, .star, .diamond]
            return ConfettiParticle(
                x: Double.random(in: 0.05...0.95),
                vx: Double.random(in: -60...60),
                vy: Double.random(in: -380 ... -120),
                size: Double.random(in: 5...12),
                color: Self.colors.randomElement()!,
                spin: Double.random(in: -4...4),
                lifetime: Double.random(in: 2.0...3.5),
                startTime: now + Double(i) * 0.025,
                shape: shapes.randomElement()!,
                wobbleSpeed: Double.random(in: 3...8),
                wobbleAmount: Double.random(in: 5...20)
            )
        }
    }
}

// MARK: - Particle Model

private enum ConfettiShape: CaseIterable {
    case rect, circle, heart, star, diamond
}

private struct ConfettiParticle {
    let x: Double
    let vx: Double
    let vy: Double
    let size: Double
    let color: Color
    let spin: Double
    let lifetime: Double
    let startTime: TimeInterval
    let shape: ConfettiShape
    let wobbleSpeed: Double
    let wobbleAmount: Double
}

// MARK: - Simple Sparkle (reduced motion)

private struct SimpleSparkleView: View {
    @State private var sparkles: [(id: Int, x: CGFloat, y: CGFloat, delay: Double)] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(sparkles, id: \.id) { sparkle in
                    SparkleSymbol()
                        .position(
                            x: sparkle.x * geo.size.width,
                            y: sparkle.y * geo.size.height
                        )
                        .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { generateSparkles() }
    }

    private func generateSparkles() {
        sparkles = (0..<12).map { i in
            (id: i,
             x: CGFloat.random(in: 0.1...0.9),
             y: CGFloat.random(in: 0.1...0.7),
             delay: Double(i) * 0.1)
        }
    }
}

private struct SparkleSymbol: View {
    @State private var visible = false
    @State private var scale: CGFloat = 0.3

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: CGFloat.random(in: 12...24), weight: .medium))
            .foregroundStyle(
                [Color.barbiePink, .barbieRose, .gold, Color(hex: "#FFD54F"), .white].randomElement()!
            )
            .scaleEffect(scale)
            .opacity(visible ? 1 : 0)
            .onAppear {
                let delay = Double.random(in: 0...0.5)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(delay)) {
                    visible = true
                    scale = 1.0
                }
                withAnimation(.easeOut(duration: 0.6).delay(delay + 1.2)) {
                    visible = false
                    scale = 0.3
                }
            }
    }
}

// MARK: - Checkbox Completion Ripple

/// A ripple ring that expands from the checkbox when a task is completed.
/// Add this as an overlay on the checkbox.
struct CheckmarkRipple: View {
    @State private var rippleScale: CGFloat = 0.5
    @State private var rippleOpacity: Double = 0.6

    var body: some View {
        Circle()
            .stroke(Color.barbiePink, lineWidth: 2)
            .frame(width: 20, height: 20)
            .scaleEffect(rippleScale)
            .opacity(rippleOpacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    rippleScale = 2.5
                    rippleOpacity = 0
                }
            }
    }
}

// MARK: - Sparkle Burst (small, for inline use)

/// A small burst of sparkles around a point. Use as overlay when something
/// exciting happens (e.g., streak milestone).
struct SparkleBurst: View {
    let count: Int
    @State private var fired = false

    init(count: Int = 6) {
        self.count = count
    }

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = Double(i) / Double(count) * 360
                Image(systemName: "sparkle")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.barbiePink.opacity(0.8))
                    .offset(
                        x: fired ? cos(angle * .pi / 180) * 18 : 0,
                        y: fired ? sin(angle * .pi / 180) * 18 : 0
                    )
                    .scaleEffect(fired ? 0.3 : 0.8)
                    .opacity(fired ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                fired = true
            }
        }
    }
}
