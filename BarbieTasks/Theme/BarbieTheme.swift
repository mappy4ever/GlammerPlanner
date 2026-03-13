import SwiftUI

// MARK: - Barbie Color Palette
// Sophisticated, chic — rose gold and blush with pink accents.
// Dark mode: deep plum, champagne gold, glowing pink.

extension Color {
    // Primary
    static let barbiePink     = Color("BarbiePink",     bundle: nil, default: Color(hex: "#E84887"))
    static let barbieDeep     = Color("BarbieDeep",     bundle: nil, default: Color(hex: "#D42F74"))
    static let barbieRose     = Color("BarbieRose",     bundle: nil, default: Color(hex: "#F06098"))

    // Surfaces
    static let blush          = Color(light: Color(hex: "#FFF0F6"), dark: Color(hex: "#35102A"))
    static let blushMid       = Color(light: Color(hex: "#FFD0E5"), dark: Color(hex: "#4D1838"))
    static let blushDeep      = Color(light: Color(hex: "#FFD4E9"), dark: Color(hex: "#3D1430"))
    static let roseGold       = Color(hex: "#E8A0B0")

    // Text
    static let inkPrimary     = Color(light: Color(hex: "#3D1028"), dark: Color(hex: "#FFD6E8"))
    static let inkSecondary   = Color(light: Color(hex: "#8A3060"), dark: Color(hex: "#F0A0C0"))
    static let inkMuted       = Color(light: Color(hex: "#C06888"), dark: Color(hex: "#B06888"))

    // Borders
    static let petal          = Color(light: Color(hex: "#F5A0C0"), dark: Color(hex: "#6E2850"))
    static let petalLight     = Color(light: Color(hex: "#FFC4DC"), dark: Color(hex: "#5A2042"))

    // Priority
    static let priHigh        = Color(hex: "#D4577A")
    static let priMed         = Color(hex: "#D4956B")
    static let priLow         = Color(hex: "#6BA3C9")

    // Gold (for accents in dark mode)
    static let gold           = Color(hex: "#D4A66B")

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
