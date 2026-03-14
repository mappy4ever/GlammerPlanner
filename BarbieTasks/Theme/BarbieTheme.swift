import SwiftUI

// MARK: - Theme-Aware Color Palette
// Colors now read dynamically from ThemeManager so they adapt to the active theme.

extension Color {
    // Primary
    static var barbiePink: Color     { ThemeManager.shared.palette.primary }
    static var barbieDeep: Color     { ThemeManager.shared.palette.primaryDeep }
    static var barbieRose: Color     { ThemeManager.shared.palette.primaryLight }

    // Surfaces
    static var blush: Color          { ThemeManager.shared.palette.surface }
    static var blushMid: Color       { ThemeManager.shared.palette.surfaceMid }
    static var blushDeep: Color      { ThemeManager.shared.palette.surfaceDeep }
    static var roseGold: Color       { ThemeManager.shared.palette.primaryLight.opacity(0.6) }

    // Text
    static var inkPrimary: Color     { ThemeManager.shared.palette.textPrimary }
    static var inkSecondary: Color   { ThemeManager.shared.palette.textSecondary }
    static var inkMuted: Color       { ThemeManager.shared.palette.textMuted }

    // Borders
    static var petal: Color          { ThemeManager.shared.palette.border }
    static var petalLight: Color     { ThemeManager.shared.palette.borderLight }

    // Priority
    static var priHigh: Color        { ThemeManager.shared.palette.priorityHigh }
    static var priMed: Color         { ThemeManager.shared.palette.priorityMed }
    static var priLow: Color         { ThemeManager.shared.palette.priorityLow }

    // Gold (for accents)
    static var gold: Color           { ThemeManager.shared.palette.accent }

    // Project presets
    static let projectColors: [String] = [
        "#D4577A", "#C27BA0", "#8E6BAD", "#6B8FBF",
        "#5A9E8F", "#7DB87D", "#C9A96B", "#D4846B",
        "#B07D9E", "#8A8A8A",
    ]

    // Hex initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }

    // Adaptive light/dark
    init(light: Color, dark: Color) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(dark)
            }
            return NSColor(light)
        })
    }

    // Named color with fallback
    init(_ name: String, bundle: Bundle?, default fallback: Color) {
        if let _ = NSColor(named: name) {
            self.init(name)
        } else {
            self = fallback
        }
    }
}

// MARK: - Button Styles

struct ChicButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(Color.barbiePink)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.smooth(duration: 0.15), value: configuration.isPressed)
    }
}

struct ChicSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(Color.blushMid)
            .foregroundStyle(Color.barbieDeep)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.smooth(duration: 0.15), value: configuration.isPressed)
    }
}
