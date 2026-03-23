// AppTheme.swift
// All design tokens for Pad Yatra. Views must use these — never hardcode colors.
import SwiftUI

// MARK: - Color Palette

extension Color {

    // MARK: Brand Palette

    /// Primary CTA, active elements.
    static let brandSaffron    = Color(hex: "#FF6B35")
    /// Warm background tints, gradients.
    static let brandPeach      = Color(hex: "#FFAD8A")
    /// Card and sheet backgrounds.
    static let brandWarmCream  = Color(hex: "#FFF4E6")
    /// Active / selected state, pressed tint.
    static let brandDeepOrange = Color(hex: "#E84A00")
    /// Primary text on light backgrounds.
    static let brandEarthBrown = Color(hex: "#6B3A2A")
    /// Achievement gold, highlights.
    static let brandGold       = Color(hex: "#FFB830")
    /// Unvisited map markers, locked states.
    static let brandTempleGrey = Color(hex: "#8A7B72")
    /// Visited checkmarks, completion badges.
    static let brandVisited    = Color(hex: "#4CAF50")

    // MARK: Semantic Aliases (use these in views)

    static let primaryBackground     = brandWarmCream
    static let primaryText           = brandEarthBrown
    static let primaryCTA            = brandSaffron
    static let achievementLocked     = brandTempleGrey
    static let achievementUnlocked   = brandGold
    static let visitedBadge          = brandVisited
    static let activeSelection       = brandDeepOrange

    // MARK: - Hex Initialiser

    /// Initialises a Color from a CSS-style hex string (#RGB, #RRGGBB, or #RRGGBBAA).
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let r, g, b, a: Double
        switch cleaned.count {
        case 6:
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >>  8) & 0xFF) / 255
            b = Double( value        & 0xFF) / 255
            a = 1.0
        case 8:
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >>  8) & 0xFF) / 255
            a = Double( value        & 0xFF) / 255
        default:
            // Fallback to clear — log-worthy in debug, silent in release.
            r = 0; g = 0; b = 0; a = 0
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Spacing

/// Consistent spacing scale. Use these constants instead of raw CGFloat values.
enum AppSpacing {
    static let xs: CGFloat =  4
    static let sm: CGFloat =  8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radii

/// Consistent corner radius scale.
enum AppRadius {
    static let sm: CGFloat =  8
    static let md: CGFloat = 12
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
}

// MARK: - Shadow Style

/// Standard card shadow. Apply via .shadow(style: .card).
struct AppShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    static let card = AppShadow(
        color: Color.black.opacity(0.08),
        radius: 8,
        x: 0,
        y: 2
    )
    static let modal = AppShadow(
        color: Color.black.opacity(0.16),
        radius: 20,
        x: 0,
        y: 8
    )
}

extension View {
    func appShadow(_ style: AppShadow = .card) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
