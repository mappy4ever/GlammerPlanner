import SwiftUI

// MARK: - Theme Palette

struct ThemePalette {
    let primary: Color
    let primaryDeep: Color
    let primaryLight: Color

    let surface: Color
    let surfaceMid: Color
    let surfaceDeep: Color

    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color

    let border: Color
    let borderLight: Color

    let priorityHigh: Color
    let priorityMed: Color
    let priorityLow: Color

    let accent: Color
}

// MARK: - Theme ID

enum AppThemeId: String, CaseIterable, Identifiable {
    case barbie
    case classic
    case wizarding
    case enchanted
    case midnight
    case nature
    case unhinged

    var id: String { rawValue }

    var name: String {
        switch self {
        case .barbie:    "Barbie"
        case .classic:   "Classic"
        case .wizarding: "Wizarding"
        case .enchanted: "Enchanted"
        case .midnight:  "Midnight"
        case .nature:    "Nature"
        case .unhinged:  "Unhinged"
        }
    }

    var tagline: String {
        switch self {
        case .barbie:    "Get it done, gorgeously"
        case .classic:   "Soft colours, sharp focus"
        case .wizarding: "Mischief managed"
        case .enchanted: "Where dreams become done"
        case .midnight:  "Dark mode, bright results"
        case .nature:    "Grow through what you go through"
        case .unhinged:  "Get sh*t done, you maniac"
        }
    }

    var icon: String {
        switch self {
        case .barbie:    "sparkles"
        case .classic:   "briefcase.fill"
        case .wizarding: "wand.and.stars"
        case .enchanted: "wand.and.stars.inverse"
        case .midnight:  "moon.stars.fill"
        case .nature:    "leaf.fill"
        case .unhinged:  "flame.fill"
        }
    }

    var palette: ThemePalette {
        switch self {
        case .barbie:    Self.barbiePalette
        case .classic:   Self.classicPalette
        case .wizarding: Self.wizardingPalette
        case .enchanted: Self.enchantedPalette
        case .midnight:  Self.midnightPalette
        case .nature:    Self.naturePalette
        case .unhinged:  Self.unhingedPalette
        }
    }

    // MARK: - Barbie Palette

    private static let barbiePalette = ThemePalette(
        primary:      Color(light: Color(hex: "#E84887"), dark: Color(hex: "#E84887")),
        primaryDeep:  Color(light: Color(hex: "#D42F74"), dark: Color(hex: "#D42F74")),
        primaryLight: Color(light: Color(hex: "#F06098"), dark: Color(hex: "#F06098")),
        surface:      Color(light: Color(hex: "#FFF0F6"), dark: Color(hex: "#35102A")),
        surfaceMid:   Color(light: Color(hex: "#FFD0E5"), dark: Color(hex: "#4D1838")),
        surfaceDeep:  Color(light: Color(hex: "#FFD4E9"), dark: Color(hex: "#3D1430")),
        textPrimary:  Color(light: Color(hex: "#3D1028"), dark: Color(hex: "#FFD6E8")),
        textSecondary: Color(light: Color(hex: "#8A3060"), dark: Color(hex: "#F0A0C0")),
        textMuted:    Color(light: Color(hex: "#C06888"), dark: Color(hex: "#B06888")),
        border:       Color(light: Color(hex: "#F5A0C0"), dark: Color(hex: "#6E2850")),
        borderLight:  Color(light: Color(hex: "#FFC4DC"), dark: Color(hex: "#5A2042")),
        priorityHigh: Color(hex: "#D4577A"),
        priorityMed:  Color(hex: "#D4956B"),
        priorityLow:  Color(hex: "#6BA3C9"),
        accent:       Color(hex: "#D4A66B")
    )

    // MARK: - Classic Palette (Pastel Rainbow / Grey-White Base)

    private static let classicPalette = ThemePalette(
        primary:      Color(light: Color(hex: "#8B7EC8"), dark: Color(hex: "#A898E0")),   // soft purple
        primaryDeep:  Color(light: Color(hex: "#7068B0"), dark: Color(hex: "#8B7EC8")),   // deeper purple
        primaryLight: Color(light: Color(hex: "#B0A8E0"), dark: Color(hex: "#C8C0F0")),   // light lavender
        surface:      Color(light: Color(hex: "#F7F6F9"), dark: Color(hex: "#1C1C20")),   // warm white/grey
        surfaceMid:   Color(light: Color(hex: "#EEEDF3"), dark: Color(hex: "#28272E")),   // light grey
        surfaceDeep:  Color(light: Color(hex: "#E4E2EC"), dark: Color(hex: "#222128")),   // grey
        textPrimary:  Color(light: Color(hex: "#3A3540"), dark: Color(hex: "#EAE8F0")),
        textSecondary: Color(light: Color(hex: "#6A6575"), dark: Color(hex: "#B0A8C0")),
        textMuted:    Color(light: Color(hex: "#9A95A8"), dark: Color(hex: "#706888")),
        border:       Color(light: Color(hex: "#D8D4E2"), dark: Color(hex: "#3A3640")),
        borderLight:  Color(light: Color(hex: "#E8E5F0"), dark: Color(hex: "#2E2B35")),
        priorityHigh: Color(hex: "#E8818A"),  // pastel red
        priorityMed:  Color(hex: "#F0C070"),  // pastel orange/yellow
        priorityLow:  Color(hex: "#7EB8D8"),  // pastel blue
        accent:       Color(light: Color(hex: "#90D4A0"), dark: Color(hex: "#A0E0B0"))  // pastel green
    )

    // MARK: - Wizarding Palette (Harry Potter: Burgundy + Gold + Midnight Blue)

    private static let wizardingPalette = ThemePalette(
        primary:      Color(light: Color(hex: "#8C1D40"), dark: Color(hex: "#C24060")),   // Gryffindor burgundy
        primaryDeep:  Color(light: Color(hex: "#6E1530"), dark: Color(hex: "#8C1D40")),   // deep maroon
        primaryLight: Color(light: Color(hex: "#B84060"), dark: Color(hex: "#D86080")),   // warm rose
        surface:      Color(light: Color(hex: "#FAF5F0"), dark: Color(hex: "#18141E")),   // parchment / dark castle
        surfaceMid:   Color(light: Color(hex: "#F0E8DD"), dark: Color(hex: "#252030")),   // aged parchment
        surfaceDeep:  Color(light: Color(hex: "#E8DDD0"), dark: Color(hex: "#1E1A28")),   // old paper
        textPrimary:  Color(light: Color(hex: "#2A1A22"), dark: Color(hex: "#F0E8DD")),   // dark ink
        textSecondary: Color(light: Color(hex: "#5A3A48"), dark: Color(hex: "#C8A888")),
        textMuted:    Color(light: Color(hex: "#8A6A78"), dark: Color(hex: "#8A7068")),
        border:       Color(light: Color(hex: "#D4B898"), dark: Color(hex: "#3A2838")),   // golden border
        borderLight:  Color(light: Color(hex: "#E8D8C0"), dark: Color(hex: "#2E2030")),
        priorityHigh: Color(hex: "#C03030"),  // Gryffindor red
        priorityMed:  Color(hex: "#D4A520"),  // wizarding gold
        priorityLow:  Color(hex: "#2A5298"),  // Ravenclaw blue
        accent:       Color(light: Color(hex: "#D4A520"), dark: Color(hex: "#E8C040"))  // golden snitch
    )

    // MARK: - Enchanted Palette

    private static let enchantedPalette = ThemePalette(
        primary:      Color(light: Color(hex: "#3B6FC2"), dark: Color(hex: "#5B8FE2")),
        primaryDeep:  Color(light: Color(hex: "#2952A3"), dark: Color(hex: "#3B6FC2")),
        primaryLight: Color(light: Color(hex: "#5B8FE2"), dark: Color(hex: "#7BAFF8")),
        surface:      Color(light: Color(hex: "#F0F4FF"), dark: Color(hex: "#0A1628")),
        surfaceMid:   Color(light: Color(hex: "#D8E4FF"), dark: Color(hex: "#142240")),
        surfaceDeep:  Color(light: Color(hex: "#C8D8F8"), dark: Color(hex: "#101C38")),
        textPrimary:  Color(light: Color(hex: "#1A2744"), dark: Color(hex: "#D4E0F8")),
        textSecondary: Color(light: Color(hex: "#4A5A7A"), dark: Color(hex: "#A0B8D8")),
        textMuted:    Color(light: Color(hex: "#7A8AA8"), dark: Color(hex: "#6A7A98")),
        border:       Color(light: Color(hex: "#A0B8D8"), dark: Color(hex: "#2A3A58")),
        borderLight:  Color(light: Color(hex: "#C0D0E8"), dark: Color(hex: "#1E2E48")),
        priorityHigh: Color(hex: "#C0392B"),
        priorityMed:  Color(hex: "#D4A66B"),
        priorityLow:  Color(hex: "#3B6FC2"),
        accent:       Color(light: Color(hex: "#D4A66B"), dark: Color(hex: "#E0B87A"))
    )

    // MARK: - Midnight Palette

    private static let midnightPalette = ThemePalette(
        primary:      Color(light: Color(hex: "#E84887"), dark: Color(hex: "#E84887")),
        primaryDeep:  Color(light: Color(hex: "#C23570"), dark: Color(hex: "#C23570")),
        primaryLight: Color(light: Color(hex: "#FF6BA8"), dark: Color(hex: "#FF6BA8")),
        surface:      Color(light: Color(hex: "#161B22"), dark: Color(hex: "#161B22")),     // lighter base
        surfaceMid:   Color(light: Color(hex: "#21262D"), dark: Color(hex: "#21262D")),     // visible sidebar items
        surfaceDeep:  Color(light: Color(hex: "#1C2128"), dark: Color(hex: "#1C2128")),     // subtle contrast
        textPrimary:  Color(light: Color(hex: "#F0F6FC"), dark: Color(hex: "#F0F6FC")),     // near-white text
        textSecondary: Color(light: Color(hex: "#B8C0CC"), dark: Color(hex: "#B8C0CC")),    // bright secondary
        textMuted:    Color(light: Color(hex: "#8B949E"), dark: Color(hex: "#8B949E")),      // visible muted
        border:       Color(light: Color(hex: "#3D444D"), dark: Color(hex: "#3D444D")),     // visible borders
        borderLight:  Color(light: Color(hex: "#30363D"), dark: Color(hex: "#30363D")),
        priorityHigh: Color(hex: "#F85149"),
        priorityMed:  Color(hex: "#D29922"),
        priorityLow:  Color(hex: "#58A6FF"),
        accent:       Color(light: Color(hex: "#58A6FF"), dark: Color(hex: "#58A6FF"))
    )

    // MARK: - Nature Palette

    private static let naturePalette = ThemePalette(
        primary:      Color(light: Color(hex: "#4A8B3F"), dark: Color(hex: "#6BAF5F")),
        primaryDeep:  Color(light: Color(hex: "#357A2B"), dark: Color(hex: "#4A8B3F")),
        primaryLight: Color(light: Color(hex: "#6BAF5F"), dark: Color(hex: "#8BCF7F")),
        surface:      Color(light: Color(hex: "#F5F8F0"), dark: Color(hex: "#1A2410")),
        surfaceMid:   Color(light: Color(hex: "#E0EAD0"), dark: Color(hex: "#283818")),
        surfaceDeep:  Color(light: Color(hex: "#D0DCC0"), dark: Color(hex: "#223014")),
        textPrimary:  Color(light: Color(hex: "#2C3E20"), dark: Color(hex: "#D4E8C4")),
        textSecondary: Color(light: Color(hex: "#5A6E4A"), dark: Color(hex: "#A0B890")),
        textMuted:    Color(light: Color(hex: "#88A070"), dark: Color(hex: "#708860")),
        border:       Color(light: Color(hex: "#A0B890"), dark: Color(hex: "#3A4E28")),
        borderLight:  Color(light: Color(hex: "#C0D0B0"), dark: Color(hex: "#2E4020")),
        priorityHigh: Color(hex: "#C0392B"),
        priorityMed:  Color(hex: "#C9A96B"),
        priorityLow:  Color(hex: "#4A8B3F"),
        accent:       Color(light: Color(hex: "#C9A96B"), dark: Color(hex: "#D4B87A"))
    )

    // MARK: - Unhinged Palette (Pastel Rainbow / Gray)

    private static let unhingedPalette = ThemePalette(
        primary:      Color(light: Color(hex: "#9050B0"), dark: Color(hex: "#B870D8")),   // stronger purple
        primaryDeep:  Color(light: Color(hex: "#703890"), dark: Color(hex: "#9050B0")),   // deep violet
        primaryLight: Color(light: Color(hex: "#B878D0"), dark: Color(hex: "#D898F0")),   // vibrant lavender
        surface:      Color(light: Color(hex: "#F8F6FA"), dark: Color(hex: "#1E1A22")),
        surfaceMid:   Color(light: Color(hex: "#EDE8F2"), dark: Color(hex: "#2A2530")),
        surfaceDeep:  Color(light: Color(hex: "#E0DAE8"), dark: Color(hex: "#242028")),
        textPrimary:  Color(light: Color(hex: "#3A2E42"), dark: Color(hex: "#E8E0F0")),
        textSecondary: Color(light: Color(hex: "#6A5A78"), dark: Color(hex: "#B8A8C8")),
        textMuted:    Color(light: Color(hex: "#9A8AA8"), dark: Color(hex: "#7A6A88")),
        border:       Color(light: Color(hex: "#C8B8D8"), dark: Color(hex: "#3E3448")),
        borderLight:  Color(light: Color(hex: "#DDD0EA"), dark: Color(hex: "#322A3C")),
        priorityHigh: Color(hex: "#E06070"),
        priorityMed:  Color(hex: "#E8A85C"),
        priorityLow:  Color(hex: "#70A8D0"),
        accent:       Color(light: Color(hex: "#F0C860"), dark: Color(hex: "#F0D070"))
    )
}

// MARK: - Theme Manager

final class ThemeManager {
    static let shared = ThemeManager()

    var current: AppThemeId {
        get { AppThemeId(rawValue: UserDefaults.standard.string(forKey: "appTheme") ?? "barbie") ?? .barbie }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "appTheme") }
    }

    var palette: ThemePalette { current.palette }

    private init() {}
}
