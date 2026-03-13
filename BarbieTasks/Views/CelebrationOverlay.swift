import SwiftUI

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
        let y = p.vy * age + 150 * age * age
        let opacity = 1.0 - progress * progress * progress
        let rotation = Angle.degrees(p.spin * age * 200)

        context.opacity = opacity

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
            let points: Int = 5
            let outerRadius: CGFloat = size
            let innerRadius: CGFloat = size * 0.4
            let totalPoints: Int = points * 2
            for i in 0..<totalPoints {
                let radius: CGFloat = i.isMultiple(of: 2) ? outerRadius : innerRadius
                let angle: Double = Double(i) * .pi / Double(points) - .pi / 2
                let px: CGFloat = cos(angle) * radius
                let py: CGFloat = sin(angle) * radius
                let point = CGPoint(x: px, y: py)
                if i == 0 { path.move(to: point) }
                else { path.addLine(to: point) }
            }
            path.closeSubpath()
        }
    }

    private func spawnParticles() {
        let count = 100
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
                withAnimation(.smooth(duration: 0.4).delay(delay)) {
                    visible = true
                    scale = 1.0
                }
                withAnimation(.smooth(duration: 0.5).delay(delay + 1.2)) {
                    visible = false
                    scale = 0.3
                }
            }
    }
}

// MARK: - Checkbox Completion Ripple

struct CheckmarkRipple: View {
    @State private var ripple1Scale: CGFloat = 0.5
    @State private var ripple1Opacity: Double = 0.6
    @State private var ripple2Scale: CGFloat = 0.5
    @State private var ripple2Opacity: Double = 0.4

    var body: some View {
        ZStack {
            // First ripple — fast
            Circle()
                .stroke(
                    LinearGradient(colors: [.barbiePink, .barbieRose], startPoint: .top, endPoint: .bottom),
                    lineWidth: 2
                )
                .frame(width: 20, height: 20)
                .scaleEffect(ripple1Scale)
                .opacity(ripple1Opacity)

            // Second ripple — delayed, wider
            Circle()
                .stroke(Color.barbiePink.opacity(0.5), lineWidth: 1)
                .frame(width: 20, height: 20)
                .scaleEffect(ripple2Scale)
                .opacity(ripple2Opacity)
        }
        .onAppear {
            withAnimation(.smooth(duration: 0.45)) {
                ripple1Scale = 3.0
                ripple1Opacity = 0
            }
            withAnimation(.smooth(duration: 0.6).delay(0.08)) {
                ripple2Scale = 4.0
                ripple2Opacity = 0
            }
        }
    }
}

// MARK: - Sparkle Burst (small, for inline use)

struct SparkleBurst: View {
    let count: Int
    @State private var fired = false

    init(count: Int = 8) {
        self.count = count
    }

    private static let colors: [Color] = [
        .barbiePink, .barbieRose, .gold, Color(hex: "#FFD54F"), Color(hex: "#FF80AB"),
    ]

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = Double(i) / Double(count) * 360
                let color = Self.colors[i % Self.colors.count]
                let icons = ["sparkle", "heart.fill", "star.fill", "sparkle"]
                Image(systemName: icons[i % icons.count])
                    .font(.system(size: CGFloat.random(in: 6...10), weight: .bold))
                    .foregroundStyle(color)
                    .offset(
                        x: fired ? cos(angle * .pi / 180) * CGFloat.random(in: 16...26) : 0,
                        y: fired ? sin(angle * .pi / 180) * CGFloat.random(in: 16...26) : 0
                    )
                    .scaleEffect(fired ? 0.2 : 1.0)
                    .opacity(fired ? 0 : 1)
                    .rotationEffect(.degrees(fired ? Double.random(in: -90...90) : 0))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                fired = true
            }
        }
    }
}

