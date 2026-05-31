
//  GlassCard.swift
//  AICustomerResverSystem

import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = AppTheme.Spacing.md
    var cornerRadius: CGFloat = AppTheme.CornerRadius.lg
    
    init(
        padding: CGFloat = AppTheme.Spacing.md,
        cornerRadius: CGFloat = AppTheme.CornerRadius.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
            }
            .shadow(
                color: .black.opacity(0.06),
                radius: 12,
                x: 0,
                y: 4
            )
    }
}

// MARK: - Stat Card (Dashboard)
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String? = nil
    var trend: Double? = nil
    
    @State private var isAnimated = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                Spacer()
                
                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                        Text(String(format: "%.1f%%", abs(trend)))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(trend >= 0 ? AppTheme.Colors.success : AppTheme.Colors.danger)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        (trend >= 0 ? AppTheme.Colors.success : AppTheme.Colors.danger).opacity(0.1)
                    )
                    .clipShape(Capsule())
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AppTheme.Typography.statValue)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .contentTransition(.numericText(value: Double(value.filter { $0.isNumber }) ?? 0))
                
                Text(title)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTheme.Typography.caption2)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                .stroke(color.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isAnimated ? 1.0 : 0.95)
        .opacity(isAnimated ? 1.0 : 0)
        .onAppear {
            withAnimation(AppTheme.Animations.smooth) {
                isAnimated = true
            }
        }
    }
}

#Preview {
    VStack {
        StatCard(
            title: "總客戶數",
            value: "128",
            icon: "person.2.fill",
            color: AppTheme.Colors.accent,
            trend: 12.5
        )
        .frame(width: 180)
    }
    .padding()
    .background(AppTheme.Colors.background)
}
