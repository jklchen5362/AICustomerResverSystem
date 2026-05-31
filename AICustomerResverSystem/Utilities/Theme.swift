
//  Theme.swift
//  AICustomerResverSystem
//  Design System — Medical Luxury Aesthetic

import SwiftUI

// MARK: - App Theme
struct AppTheme {
    
    // MARK: - Colors
    struct Colors {
        // Primary Palette
        static let primary = Color(hex: "1A1A2E")
        static let primaryLight = Color(hex: "2D2D44")
        static let accent = Color(hex: "C9A96E")
        static let accentLight = Color(hex: "D4BC8E")
        static let accentSecondary = Color(hex: "4ECDC4")
        
        // Backgrounds
        static let background = Color(hex: "F8F9FA")
        static let cardBackground = Color.white.opacity(0.85)
        static let darkBackground = Color(hex: "0F0F1A")
        
        // Semantic
        static let success = Color(hex: "2ECC71")
        static let warning = Color(hex: "F39C12")
        static let danger = Color(hex: "E74C3C")
        static let info = Color(hex: "3498DB")
        
        // Text
        static let textPrimary = Color(hex: "1A1A2E")
        static let textSecondary = Color(hex: "6C757D")
        static let textTertiary = Color(hex: "ADB5BD")
        static let textOnDark = Color.white
        
        // Status Colors
        static let statusConfirmed = Color(hex: "3498DB")
        static let statusArrived = Color(hex: "2ECC71")
        static let statusCompleted = Color(hex: "4ECDC4")
        static let statusCancelled = Color(hex: "E74C3C")
        static let statusNoShow = Color(hex: "95A5A6")
        
        // VIP Colors
        static let vipGold = Color(hex: "FFD700")
        static let vipSilver = Color(hex: "C0C0C0")
        static let vipBronze = Color(hex: "CD7F32")
        static let vipPlatinum = Color(hex: "E5E4E2")
        
        // Gradients
        static let primaryGradient = LinearGradient(
            colors: [Color(hex: "1A1A2E"), Color(hex: "2D2D44")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let accentGradient = LinearGradient(
            colors: [Color(hex: "C9A96E"), Color(hex: "D4BC8E")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cardGradient = LinearGradient(
            colors: [Color.white.opacity(0.9), Color.white.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let dashboardGradient = LinearGradient(
            colors: [Color(hex: "1A1A2E"), Color(hex: "16213E"), Color(hex: "0F3460")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Session Progress Colors
        static func sessionColor(percentage: Double) -> Color {
            if percentage > 0.5 { return success }
            if percentage > 0.2 { return warning }
            return danger
        }
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let callout = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)
        static let caption2 = Font.system(size: 11, weight: .regular)
        
        // Specialized
        static let statValue = Font.system(size: 28, weight: .bold, design: .rounded)
        static let cardTitle = Font.system(size: 14, weight: .medium)
        static let tabLabel = Font.system(size: 10, weight: .medium)
        static let badge = Font.system(size: 11, weight: .bold)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        static let huge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let pill: CGFloat = 50
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let card = ShadowStyle(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        static let elevated = ShadowStyle(color: .black.opacity(0.1), radius: 20, x: 0, y: 8)
        static let subtle = ShadowStyle(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        static let glow = ShadowStyle(color: Colors.accent.opacity(0.3), radius: 16, x: 0, y: 4)
    }
    
    // MARK: - Animation
    struct Animations {
        static let quick = Animation.easeInOut(duration: 0.2)
        static let standard = Animation.easeInOut(duration: 0.35)
        static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let gentle = Animation.easeOut(duration: 0.5)
    }
    
    // MARK: - Icon Sizes
    struct IconSize {
        static let sm: CGFloat = 16
        static let md: CGFloat = 20
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 44
    }
}

// MARK: - Shadow Style Helper
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extension (Hex)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.CornerRadius.lg
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: AppTheme.Shadows.card.color,
                radius: AppTheme.Shadows.card.radius,
                x: AppTheme.Shadows.card.x,
                y: AppTheme.Shadows.card.y
            )
    }
}

struct ElevatedCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
            .shadow(
                color: AppTheme.Shadows.elevated.color,
                radius: AppTheme.Shadows.elevated.radius,
                x: AppTheme.Shadows.elevated.x,
                y: AppTheme.Shadows.elevated.y
            )
    }
}

struct AccentBorderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                    .stroke(AppTheme.Colors.accent.opacity(0.3), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = AppTheme.CornerRadius.lg) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
    
    func elevatedCard() -> some View {
        modifier(ElevatedCardModifier())
    }
    
    func accentBorder() -> some View {
        modifier(AccentBorderModifier())
    }
    
    func shimmer(isActive: Bool = true) -> some View {
        self.redacted(reason: isActive ? .placeholder : [])
    }
}
