//  DashboardCardView.swift
//  AICustomerResverSystem

import SwiftUI

struct DashboardCardView: View {
    @Environment(AppState.self) private var appState
    @State private var animateGradient = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(greetingText)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text("\(appState.currentUser?.displayName ?? "諮詢顧問")")
                        .font(AppTheme.Typography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                HStack(spacing: AppTheme.Spacing.xxs) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 12))
                    Text(appState.selectedBranch?.name ?? "台北總店")
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(AppTheme.Colors.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.white.opacity(0.12))
                .clipShape(Capsule())
            }
            
            Spacer()
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Date().formattedWeekday)
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.Colors.accent)
                    
                    Text(Date().formattedShortDate)
                        .font(AppTheme.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                HStack(spacing: AppTheme.Spacing.sm) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("系統狀態")
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(AppTheme.Colors.success)
                                .frame(width: 6, height: 6)
                            Text("已同步 Online")
                                .font(AppTheme.Typography.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.Colors.success)
                        }
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .frame(height: 170)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "1A1A2E"),
                            animateGradient ? Color(hex: "16213E") : Color(hex: "252A4A"),
                            Color(hex: "0F3460")
                        ],
                        startPoint: animateGradient ? .topLeading : .bottomLeading,
                        endPoint: animateGradient ? .bottomTrailing : .topTrailing
                    )
                )
                .animation(.linear(duration: 8.0).repeatForever(autoreverses: true), value: animateGradient)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                .stroke(AppTheme.Colors.accent.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color(hex: "1A1A2E").opacity(0.15), radius: 15, x: 0, y: 8)
        .onAppear {
            animateGradient = true
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 5 { return "深夜好，辛苦了" }
        if hour < 11 { return "早安，開啟美好的一天" }
        if hour < 14 { return "午安，辛苦了" }
        if hour < 18 { return "下午好， clinic 精英" }
        return "晚安，願您今晚愉快"
    }
}

#Preview {
    DashboardCardView()
        .padding()
        .environment(AppState())
}
